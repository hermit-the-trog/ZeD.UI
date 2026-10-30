-- ZeD-UI/42/media/lua/client/ZeD/ItemCard.lua
-- ============================================================================
-- O08: ITEM CARD — Sticky head + scrollable body
-- Head (top, pinned): Icon + Name + Primary bar + Action strip
-- Body (below, scrolls): Badges, Stats, Category/Weight, Foldable disclosures
-- Disclosures: Per-Zone Detail (clothing), Nutrition/Ingredients (food)
-- Fold state persisted per item TYPE via player modData.
-- ============================================================================
require "ISUI/ISPanel"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
ZeD = ZeD or {}
ZeD_ItemCard = ISPanel:derive("ZeD_ItemCard")

local safeGet = ZeD.Atoms.safeGet

local wrapText = ZeD.Atoms.wrapText

local function getStatRowH()
    local T = ZeD.T
    local a = ZeD.TM:getFontHeight(T.fontF1)
    local b = ZeD.TM:getFontHeight(T.fontF2)
    local tall = math.max(a, b)
    return tall + math.max(T.px(2), math.floor(tall * 0.15))
end

local function getItemCategory(item)
    if not item then return "Item" end
    if safeGet(item, "getFluidContainer") then return "Fluid" end
    if instanceof(item, "HandWeapon") then
        local ammo = safeGet(item, "getAmmoType")
        if ammo and ammo ~= "" then return "Firearm" end
        return "Weapon"
    end
    local cat = safeGet(item, "getCategory")
    if cat == "Food" then return "Food" end
    if cat == "Clothing" then return "Clothing" end
    if instanceof(item, "DrainableComboItem") then return "Drainable" end
    if cat == "Literature" then return "Literature" end
    local cap = safeGet(item, "getItemCapacity")
    if cat == "Container" or (cap and cap > 0) then return "Container" end
    if instanceof(item, "Key") then return "Key" end
    if safeGet(item, "canEmitLight") then return "Light" end
    return "Item"
end

local function getStatusAlerts(item)
    local al = {}
    if safeGet(item,"isBroken") then table.insert(al,{text="Broken",variant="danger"}) end
    local w = safeGet(item,"getWetness"); if w and w>15 then table.insert(al,{text="Wet",variant="warning"}) end
    if safeGet(item,"isRotten") then table.insert(al,{text="Rotten",variant="danger"})
    elseif safeGet(item,"isBurnt") then table.insert(al,{text="Burnt",variant="warning"}) end
    if safeGet(item,"isFrozen") then table.insert(al,{text="Frozen",variant="info"}) end
    if safeGet(item,"isTainted") or safeGet(item,"isTaintedWater") then table.insert(al,{text="Tainted",variant="danger"}) end
    if safeGet(item,"isActivated") then table.insert(al,{text="On",variant="positive"}) end
    if safeGet(item,"isEquipped") then table.insert(al,{text="Equipped",variant="accent"}) end
    if safeGet(item,"isFavorite") then table.insert(al,{text="Fav",variant="accent"}) end
    if safeGet(item,"hasBlood") then table.insert(al,{text="Bloody",variant="danger"}) end
    if safeGet(item,"hasDirt") then table.insert(al,{text="Dirty",variant="warning"}) end
    if safeGet(item,"isbDangerousUncooked") and not safeGet(item,"isCooked") and not safeGet(item,"isBurnt") then
        table.insert(al,{text="Raw!",variant="danger"}) end
    return al
end

local function formatWeapon(item)
    local s = {}
    local mn,mx = safeGet(item,"getMinDamage"),safeGet(item,"getMaxDamage")
    if mn and mx then table.insert(s,{label="Damage",value=string.format("%.1f - %.1f",mn,mx)}) end
    local sp = safeGet(item,"getBaseSpeed")
    if sp then local l="Normal"; if sp<1 then l="Fast" elseif sp>2 then l="Slow" end; table.insert(s,{label="Speed",value=l}) end
    local r = safeGet(item,"getMaxRange"); if r and r>0 then table.insert(s,{label="Range",value=string.format("%.1f",r)}) end
    local c = safeGet(item,"getCriticalChance"); if c and c>0 then table.insert(s,{label="Crit",value=math.floor(c).."%"}) end
    local k = safeGet(item,"getKnockbackPower"); if k and k>0 then table.insert(s,{label="Knockback",value=string.format("%.1f",k)}) end
    local t = safeGet(item,"getTreeDamage"); if t and t>0 then table.insert(s,{label="Tree dmg",value=string.format("%.0f",t)}) end
    return s
end
local function formatFirearm(item)
    local s = {}
    local mn,mx = safeGet(item,"getMinDamage"),safeGet(item,"getMaxDamage")
    if mn and mx then table.insert(s,{label="Damage",value=string.format("%.1f - %.1f",mn,mx)}) end
    local r = safeGet(item,"getMaxRange"); if r and r>0 then table.insert(s,{label="Range",value=string.format("%.1f",r)}) end
    local c = safeGet(item,"getCriticalChance"); if c and c>0 then table.insert(s,{label="Crit",value=math.floor(c).."%"}) end
    local cur,mx2 = safeGet(item,"getCurrentAmmoCount"),safeGet(item,"getMaxAmmo")
    if mx2 and mx2>0 then table.insert(s,{label="Ammo",value=(cur or 0).."/"..mx2}) end
    local at = safeGet(item,"getAmmoType"); if at and at~="" then table.insert(s,{label="Ammo type",value=at:match("%.(.+)") or at}) end
    return s
end
local function formatFood(item)
    local T=ZeD.T; local s={}
    -- Player-affecting stats only — nutrition (calories/carbs/proteins/fat) moved to nutrition label
    local h=safeGet(item,"getHungerChange"); if h and h~=0 then local v=math.floor(h*100); table.insert(s,{label="Hunger",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end
    local t=safeGet(item,"getThirstChange"); if t and t~=0 then local v=math.floor(t*100); table.insert(s,{label="Thirst",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end
    local b=safeGet(item,"getUnhappyChange") or safeGet(item,"getBoredomChange"); if b and b~=0 then local v=math.floor(b); table.insert(s,{label="Boredom",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end
    local alc=safeGet(item,"getAlcoholPower"); if alc and alc>0 then table.insert(s,{label="Alcohol",value=string.format("%.1f",alc),color=T.warning}) end
    local poi=safeGet(item,"getPoisonPower"); if poi and poi>0 then table.insert(s,{label="Poison",value=string.format("%.0f",poi),color=T.danger}) end
    local heat=safeGet(item,"getHeat")
    if heat and heat>1.3 then table.insert(s,{label="Temp",value="Hot",color=T.warning})
    elseif heat and heat<0.5 then table.insert(s,{label="Temp",value="Cold",color=T.info}) end
    if safeGet(item,"isGoodHot") then table.insert(s,{label="Note",value="Better hot",color=T.positive}) end
    if safeGet(item,"isBadCold") then table.insert(s,{label="Note",value="Bad cold",color=T.warning}) end
    if safeGet(item,"isCooked") and not safeGet(item,"isBurnt") then table.insert(s,{label="Status",value="Cooked",color=T.positive}) end
    return s
end
local function formatClothing(item)
    local T=ZeD.T; local s={}
    -- Body location moved to Zone 1 stat anchor (getItemSubtype)
    local bite=safeGet(item,"getBiteDefense"); if bite and bite>0 then table.insert(s,{label="Bite def.",value=math.floor(bite).."%"}) end
    local scr=safeGet(item,"getScratchDefense"); if scr and scr>0 then table.insert(s,{label="Scratch",value=math.floor(scr).."%"}) end
    local cm=safeGet(item,"getCombatSpeedModifier"); if cm and cm~=0 then table.insert(s,{label="Move pen.",value=string.format("%.1f",cm),color=cm>0 and T.warning or T.positive}) end
    local fab=safeGet(item,"getFabricType"); if fab and tostring(fab)~="" then table.insert(s,{label="Fabric",value=tostring(fab)}) end
    local wet=safeGet(item,"getWetness"); if wet and wet>0 then table.insert(s,{label="Wetness",value=math.floor(wet).."%",color=wet>50 and T.danger or (wet>15 and T.warning or T.textSec)}) end
    return s
end
local function formatFluid(item)
    local T=ZeD.T; local s={}
    local fc=safeGet(item,"getFluidContainer"); if not fc then return s end
    local fluid=safeGet(fc,"getPrimaryFluid")
    if fluid then local fn=safeGet(fluid,"getTranslatedFluidName") or safeGet(fluid,"getFluidTypeString"); if fn and tostring(fn)~="" then table.insert(s,{label="Contents",value=tostring(fn)}) end end
    local amt,cap=safeGet(fc,"getAmount"),safeGet(fc,"getCapacity")
    if amt and cap and cap>0 then local str=cap<1 and string.format("%.0f / %.0f mL",amt*1000,cap*1000) or string.format("%.1f / %.1f L",amt,cap); table.insert(s,{label="Amount",value=str}) end
    local props=safeGet(fc,"getProperties")
    if props then
        local fH=safeGet(props,"getHungerChange"); if fH and fH~=0 then local v=math.floor(fH*100); table.insert(s,{label="Hunger",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end
        local fT=safeGet(props,"getThirstChange"); if fT and fT~=0 then local v=math.floor(fT*100); table.insert(s,{label="Thirst",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end
        local fU=safeGet(props,"getUnhappyChange"); if fU and fU~=0 then local v=math.floor(fU); table.insert(s,{label="Boredom",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end
        local fA=safeGet(props,"getAlcohol"); if fA and fA>0 then table.insert(s,{label="Alcohol",value=string.format("%.2f",fA),color=T.warning}) end
        local fC=safeGet(props,"getCalories"); if fC and fC>0 then table.insert(s,{label="Calories",value=string.format("%.0f",fC)}) end
        local fP=safeGet(props,"getProteins"); if fP and fP>0 then table.insert(s,{label="Proteins",value=string.format("%.1f",fP)}) end
        local fCb=safeGet(props,"getCarbohydrates"); if fCb and fCb>0 then table.insert(s,{label="Carbs",value=string.format("%.1f",fCb)}) end
        local fL=safeGet(props,"getLipids"); if fL and fL>0 then table.insert(s,{label="Fat",value=string.format("%.1f",fL)}) end
    end
    local hu=safeGet(item,"getHungerChange")
    if hu and hu~=0 then local has=false; for _,x in ipairs(s) do if x.label=="Hunger" then has=true break end end
        if not has then local v=math.floor(hu*100); table.insert(s,{label="Hunger",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end end
    local th=safeGet(item,"getThirstChange")
    if th and th~=0 then local has=false; for _,x in ipairs(s) do if x.label=="Thirst" then has=true break end end
        if not has then local v=math.floor(th*100); table.insert(s,{label="Thirst",value=string.format("%+d",v),color=v<0 and T.positive or T.warning}) end end
    if safeGet(fc,"isTainted") then table.insert(s,{label="Quality",value="Tainted",color=T.danger}) end
    local tk=safeGet(fc,"isTaintedStatusKnown"); if tk==false then table.insert(s,{label="Quality",value="Unknown"}) end
    return s
end
local function formatContainer(item)
    local s={}; local cap=safeGet(item,"getItemCapacity"); if cap and cap>0 then table.insert(s,{label="Capacity",value=math.floor(cap)}) end
    local cw=safeGet(item,"getCapacityWeight"); if cw and cw>0 then table.insert(s,{label="Max weight",value=string.format("%.1f kg",cw)}) end; return s
end
local function formatLiterature(item)
    local s={}; local sk=safeGet(item,"getSkillTrained"); if sk then table.insert(s,{label="Skill",value=tostring(sk)}) end
    local lv=safeGet(item,"getLvlSkillTrained"); if lv and lv>0 then table.insert(s,{label="Level",value=lv}) end
    local ml=safeGet(item,"getMaxLevelTrained"); if ml and ml>0 and ml~=lv then table.insert(s,{label="Max level",value=ml}) end
    local pg=safeGet(item,"getNumberOfPages"); local rd=safeGet(item,"getAlreadyReadPages")
    if pg and pg>0 then table.insert(s,{label="Pages",value=(rd or 0).."/"..pg}) end; return s
end
local function formatDrainable(item)
    local s={}; local u=safeGet(item,"getCurrentUsesFloat"); local d=safeGet(item,"getUseDelta")
    if u and d and d>0 then table.insert(s,{label="Uses",value=math.floor(u/d).."/"..math.floor(1/d)}) end; return s
end
local function formatKey(item)
    local s={}; local k=safeGet(item,"getKeyId"); if k and k>=0 then table.insert(s,{label="Key ID",value=k}) end; return s
end
local function formatLight(item)
    local T=ZeD.T; local s={}
    local str=safeGet(item,"getLightStrength"); if str and str>0 then table.insert(s,{label="Brightness",value=string.format("%.1f",str)}) end
    if safeGet(item,"isActivated") then table.insert(s,{label="Status",value="On",color=T.positive}) else table.insert(s,{label="Status",value="Off"}) end; return s
end
local function getStatsForItem(item)
    local c=getItemCategory(item)
    if c=="Weapon" then return formatWeapon(item) elseif c=="Firearm" then return formatFirearm(item)
    elseif c=="Food" then return formatFood(item) elseif c=="Clothing" then return formatClothing(item)
    elseif c=="Fluid" then return formatFluid(item) elseif c=="Container" then return formatContainer(item)
    elseif c=="Literature" then return formatLiterature(item) elseif c=="Drainable" then return formatDrainable(item)
    elseif c=="Key" then return formatKey(item) elseif c=="Light" then return formatLight(item) end; return {}
end
local function getBarsForItem(item)
    local bars={}; local c=getItemCategory(item)
    if c=="Food" then local oa=safeGet(item,"getOffAge"); if oa and oa>0 then local a=safeGet(item,"getAge") or 0; table.insert(bars,{label="Freshness",ratio=math.max(0,math.min(1,1-(a/oa)))}) end end
    if c=="Drainable" then local u=safeGet(item,"getCurrentUsesFloat"); if u then table.insert(bars,{label="Uses",ratio=math.max(0,math.min(1,u))}) end end
    if c=="Firearm" then local cu=safeGet(item,"getCurrentAmmoCount"); local mx=safeGet(item,"getMaxAmmo"); if cu and mx and mx>0 then table.insert(bars,{label="Ammo",ratio=math.max(0,math.min(1,cu/mx))}) end end
    if c=="Clothing" then local w=safeGet(item,"getWetness"); if w and w>0 then table.insert(bars,{label="Wetness",ratio=math.max(0,math.min(1,w/100))}) end end
    if c=="Fluid" then local fc=safeGet(item,"getFluidContainer"); if fc then local a=safeGet(fc,"getAmount"); local cp=safeGet(fc,"getCapacity"); if a and cp and cp>0 then table.insert(bars,{label="Fill",ratio=math.max(0,math.min(1,a/cp))}) end end end
    if c=="Literature" then local pg=safeGet(item,"getNumberOfPages"); local rd=safeGet(item,"getAlreadyReadPages"); if pg and pg>0 and rd then table.insert(bars,{label="Read",ratio=math.max(0,math.min(1,rd/pg))}) end end
    local cond=safeGet(item,"getCondition"); local mc=safeGet(item,"getConditionMax")
    if cond and mc and mc>0 then table.insert(bars,{label="Condition",ratio=math.max(0,math.min(1,cond/mc))}) end; return bars
end

local function getNutritionForItem(item)
    if not instanceof(item, "Food") then return {} end
    local n = {}
    -- Serving size: whole item = 1 serving, use item weight in grams
    local wt = safeGet(item,"getActualWeight") or safeGet(item,"getWeight") or 0
    if wt > 0 then
        table.insert(n, {label="Serving Size", value=string.format("%.1f kg", wt)})
    end
    -- NLEA 21 CFR 101.9 mandatory order
    local cal = safeGet(item,"getCalories")
    table.insert(n, {label="Calories", value=cal and cal>0 and string.format("%.0f",cal) or "0"})
    local lip = safeGet(item,"getLipids")
    table.insert(n, {label="Total Fat", value=lip and lip>0 and string.format("%.1fg",lip) or "0g"})
    table.insert(n, {label="  Sat. Fat", value="-", sub=true})
    table.insert(n, {label="  Trans Fat", value="-", sub=true})
    table.insert(n, {label="Cholesterol", value="-"})
    table.insert(n, {label="Sodium", value="-"})
    local carbs = safeGet(item,"getCarbohydrates")
    table.insert(n, {label="Total Carb", value=carbs and carbs>0 and string.format("%.1fg",carbs) or "0g"})
    table.insert(n, {label="  Fiber", value="-", sub=true})
    table.insert(n, {label="  Sugars", value="-", sub=true})
    local prot = safeGet(item,"getProteins")
    table.insert(n, {label="Protein", value=prot and prot>0 and string.format("%.1fg",prot) or "0g"})
    return n
end

local function getIngredientsForItem(item)
    if not instanceof(item, "Food") then return {} end
    local ingr = {}
    local extras = safeGet(item, "getExtraItems")
    if extras then
        for i = 0, extras:size() - 1 do
            local fullType = extras:get(i)
            local script = ScriptManager.instance:getItem(fullType)
            local name = fullType:match("%.(.+)") or fullType
            if script then name = script:getDisplayName() or name end
            table.insert(ingr, { name = name, spice = false })
        end
    end
    local spices = safeGet(item, "getSpices")
    if spices then
        for i = 0, spices:size() - 1 do
            local fullType = spices:get(i)
            local script = ScriptManager.instance:getItem(fullType)
            local name = fullType:match("%.(.+)") or fullType
            if script then name = script:getDisplayName() or name end
            table.insert(ingr, { name = name, spice = true })
        end
    end
    -- Fallback: if no evolved ingredients, the item itself is the ingredient
    if #ingr == 0 then
        local dn = safeGet(item, "getDisplayName") or "???"
        table.insert(ingr, { name = dn, spice = false })
    end
    return ingr
end

-- ---------------------------------------------------------------------------
-- Shared material search for clothing repair/padding.
-- Returns needle, thread, fabric or nil, nil, nil.
-- ---------------------------------------------------------------------------
local function findClothingMaterials(player)
    local inv = player:getInventory()
    local needle = inv:getFirstTagRecurse(ItemTag.SEWING_NEEDLE)
                or inv:getItemFromType("Needle", true, true)
    local thread = inv:getFirstTagRecurse(ItemTag.THREAD)
                or inv:getItemFromType("Thread", true, true)
    local fabric = inv:getItemFromType("RippedSheets", true, true)
                or inv:getItemFromType("DenimStrips", true, true)
                or inv:getItemFromType("LeatherStrips", true, true)
    if needle and thread and fabric then
        return needle, thread, fabric
    end
    return nil, nil, nil
end

-- ---------------------------------------------------------------------------
-- Verb dispatch table — maps verb key → handler(card, def).
-- Clothing verbs use ISRepairClothing; weapon verbs use FixingManager/ISFixAction.
-- ---------------------------------------------------------------------------
local VERB_DISPATCH = {}

-- a word over the character's head when a verb can't run (vanilla's halo note)
local function note(player, text) pcall(function() player:setHaloNote(text) end) end

-- a care verb pressed without what it needs: the character says its NEEDS line
local function noteNeeds(card, key)
    local player = getSpecificPlayer(card.playerNum or 0)
    local ab = card.verbAbility and card:verbAbility(key)
    if player and ab and ab.needs and ZeD.Disclose then
        note(player, ZeD.Disclose.needsLine({ label = ab.label, needs = ab.needs }))
    end
end

VERB_DISPATCH.repair_all = function(card)
    local player = getSpecificPlayer(card.playerNum)
    if not player then return end
    local item = card.item
    local parts = safeGet(item, "getCoveredParts")
    if not parts then return end
    local needle, thread, fabric = findClothingMaterials(player)
    if not needle then noteNeeds(card, "repair_all"); return end
    for i = 0, parts:size() - 1 do
        local part   = parts:get(i)
        local visual = safeGet(item, "getVisual")
        local hc = 0
        if visual then
            local ok, v = pcall(function() return visual:getHole(part) end)
            if ok and v then hc = v end
        end
        local patch = safeGet(item, "getPatchType", part)
        if hc > 0 and not patch then
            ISTimedActionQueue.add(ISRepairClothing:new(player, item, part, fabric, thread, needle))
        end
    end
end

VERB_DISPATCH.pad_all = function(card)
    local player = getSpecificPlayer(card.playerNum)
    if not player then return end
    local item = card.item
    local parts = safeGet(item, "getCoveredParts")
    if not parts then return end
    local needle, thread, fabric = findClothingMaterials(player)
    if not needle then noteNeeds(card, "pad_all"); return end
    for i = 0, parts:size() - 1 do
        local part   = parts:get(i)
        local visual = safeGet(item, "getVisual")
        local hc = 0
        if visual then
            local ok, v = pcall(function() return visual:getHole(part) end)
            if ok and v then hc = v end
        end
        local patch = safeGet(item, "getPatchType", part)
        if hc == 0 and not patch then
            ISTimedActionQueue.add(ISRepairClothing:new(player, item, part, fabric, thread, needle))
        end
    end
end

-- Shared: find the first available fixer for a given fixing, then delegate to
-- vanilla onFix which handles transferIfNeeded + ISFixAction queuing.
local function tryFixingManager(card)
    local player = getSpecificPlayer(card.playerNum)
    if not player then return end
    local item = card.item
    local fixingList = FixingManager.getFixes(item)
    if not fixingList or fixingList:isEmpty() then return end
    -- Use first fixing with an available fixer
    for fi = 0, fixingList:size() - 1 do
        local fixing = fixingList:get(fi)
        for xi = 0, fixing:getFixers():size() - 1 do
            local fixer = fixing:getFixers():get(xi)
            if fixing:haveThisFixer(player, fixer, item) then
                ISInventoryPaneContextMenu.onFix(item, card.playerNum, fi, xi)
                return
            end
        end
    end
    -- No fixer in the bags: the character says what the repair needs (the
    -- greyed verb still answers a press with its reason, cohesion spec 9)
    noteNeeds(card, "repair")
end

VERB_DISPATCH.repair  = function(card) tryFixingManager(card) end

-- the nearest water within two tiles of the player (vanilla's wash reach), or nil
local function waterInReach(player)
    local sq = player:getCurrentSquare()
    local best, bestD = nil, nil
    if sq then
        local cell = getCell()
        for dx = -2, 2 do
            for dy = -2, 2 do
                local s = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
                local objs = s and s:getObjects()
                for i = 0, (objs and objs:size() or 0) - 1 do
                    local o = objs:get(i)
                    local ok, has = pcall(function() return o:hasWater() and o:getFluidAmount() > 0 end)
                    local d = dx * dx + dy * dy
                    if ok and has and (not bestD or d < bestD) then best, bestD = o, d end
                end
            end
        end
    end
    return best
end

-- vanilla's sharpening recipes the player can run on the item now
local SHARPEN_RECIPES = { "SharpenBlade", "SharpenBladePoorlyWithFile" }
local function sharpenRecipe(player, item)
    local SM = getScriptManager()
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    for _, name in ipairs(SHARPEN_RECIPES) do
        local recipe = SM:getCraftRecipe(name)
        if recipe then
            local logic = HandcraftLogic.new(player, nil, nil)
            logic:setContainers(containers)
            logic:setRecipeFromContextClick(recipe, item)
            if logic:canPerformCurrentRecipe() then return recipe end
        end
    end
    return nil
end

-- SHARPEN: vanilla's own (ISFirearmRadialMenu.sharpenWeapon): the whetstone
-- recipe, else the poor one with a file; it ran a repair before (Oct 19 2026).
VERB_DISPATCH.sharpen = function(card)
    local player = getSpecificPlayer(card.playerNum)
    if not (player and card.item) then return end
    local recipe = sharpenRecipe(player, card.item)
    if recipe then
        ISInventoryPaneContextMenu.OnNewCraft(card.item, recipe, card.playerNum, false)
        return
    end
    note(player, ZeD.tr("UI_ZeD_Card_NeedWhetstone"))
end

-- WASH: vanilla's own wash (ISWorldObjectContextMenu.onWashClothing: walks to
-- the water, uses soap when you carry it) at the nearest water within two
-- tiles; none in reach says so (Oct 19 2026: the button did nothing).
VERB_DISPATCH.wash = function(card)
    local player = getSpecificPlayer(card.playerNum)
    if not (player and card.item) then return end
    local best = waterInReach(player)
    if not best then note(player, ZeD.tr("UI_ZeD_Card_NoWaterInReach")); return end
    local soap = player:getInventory():getSoapList(nil, true)
    ISWorldObjectContextMenu.onWashClothing(player, best, soap, nil, card.item)
end

-- ---------------------------------------------------------------------------
-- WHAT A CARE VERB NEEDS (conditional disclosure, cohesion spec 9a)
-- For each care verb of the card (Wash, Repair, Pad, Sharpen): can it be done
-- now (canDo), does it make sense now (sensible: Repair on a garment with no
-- holes, or on a weapon in full condition, does not: the verb is gone), what it
-- needs (needs: plain words for its NEEDS line and the folded row's hint) and
-- the "you could ..." words (hint). The words name only what the game itself
-- shows for the item (its sewing kit, water, a whetstone, its repair list).
-- Worked out once a second per card: they walk the bags and the squares.
-- ---------------------------------------------------------------------------
local ABILITY_MS = 1000

-- a garment's parts with a hole and no patch, and the parts that could take padding
local function holesAndPads(item)
    local parts = safeGet(item, "getCoveredParts")
    if not parts then return 0, 0 end
    local holes, pads = 0, 0
    local visual = safeGet(item, "getVisual")
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        local hc = 0
        if visual then
            local ok, v = pcall(function() return visual:getHole(part) end)
            if ok and v then hc = v end
        end
        if not safeGet(item, "getPatchType", part) then
            if hc > 0 then holes = holes + 1 else pads = pads + 1 end
        end
    end
    return holes, pads
end

-- the item's vanilla repairs (FixingManager): whether it has any, and whether a fixer is in the bags
local function fixState(player, item)
    local list = FixingManager and FixingManager.getFixes(item)
    if not list or list:isEmpty() then return false, false end
    for fi = 0, list:size() - 1 do
        local fixing = list:get(fi)
        for xi = 0, fixing:getFixers():size() - 1 do
            if fixing:haveThisFixer(player, fixing:getFixers():get(xi), item) then return true, true end
        end
    end
    return true, false
end

local function workOutAbility(card, key)
    local player = getSpecificPlayer(card.playerNum or 0)
    local item = card.item
    local a = { canDo = true, sensible = true }
    if not (player and item) then return a end
    local VT = ZeD.ItemCard and ZeD.ItemCard.verbText
    if key == "repair_all" or key == "pad_all" then
        local holes, pads = holesAndPads(item)
        a.sensible = (key == "repair_all") and holes > 0 or pads > 0
        a.canDo = findClothingMaterials(player) ~= nil
        a.needs = ZeD.tr("UI_ZeD_Card_NeedsSewing")
        a.hint = ZeD.tr(key == "repair_all" and "UI_ZeD_Card_HintRepairHoles" or "UI_ZeD_Card_HintPad")
        a.label = VT and VT(key == "repair_all" and "REPAIR" or "PAD")
    elseif key == "wash" then
        a.canDo = waterInReach(player) ~= nil
        a.needs = ZeD.tr("UI_ZeD_Card_NeedsWater")
        a.hint = ZeD.tr("UI_ZeD_Card_HintWash")
        a.label = VT and VT("WASH")
    elseif key == "repair" then
        local has, can = fixState(player, item)
        local condMax = safeGet(item, "getConditionMax") or 0
        a.sensible = has and (safeGet(item, "getCondition") or condMax) < condMax
        a.canDo = can
        a.needs = ZeD.tr("UI_ZeD_Card_NeedsFixer")
        a.hint = ZeD.tr("UI_ZeD_Card_HintRepair")
        a.label = VT and VT("REPAIR")
    elseif key == "sharpen" then
        a.canDo = sharpenRecipe(player, item) ~= nil
        a.needs = ZeD.tr("UI_ZeD_Card_NeedsWhetstone")
        a.hint = ZeD.tr("UI_ZeD_Card_HintSharpen")
        a.label = VT and VT("SHARPEN")
    end
    return a
end

--- The care verb's ability now ({ canDo, sensible, needs, hint, label }), kept a second.
function ZeD_ItemCard:verbAbility(key)
    local now = getTimestampMs()
    local c = self._abil
    if not c or c.item ~= self.item or now - (c.t or 0) > ABILITY_MS then
        c = { item = self.item, t = now }
        self._abil = c
    end
    local a = c[key]
    if a == nil then
        local ok, r = pcall(workOutAbility, self, key)
        a = ok and r or { canDo = true, sensible = true }
        c[key] = a
    end
    return a
end

-- ---------------------------------------------------------------------------
-- Clean display names for BloodBodyPartType enum values.
-- PZ gives us "Torso_Upper", "UpperArm_L" etc. — inconsistent grammar.
-- ---------------------------------------------------------------------------
local ZONE_DISPLAY_NAMES = {
    Torso_Upper  = "Upper Torso",
    Torso_Lower  = "Lower Torso",
    Back         = "Back",
    UpperArm_L   = "Left Upper Arm",
    UpperArm_R   = "Right Upper Arm",
    ForeArm_L    = "Left Forearm",
    ForeArm_R    = "Right Forearm",
    Head         = "Head",
    Neck         = "Neck",
    Groin        = "Groin",
    UpperLeg_L   = "Left Thigh",
    UpperLeg_R   = "Right Thigh",
    LowerLeg_L   = "Left Shin",
    LowerLeg_R   = "Right Shin",
    Foot_L       = "Left Foot",
    Foot_R       = "Right Foot",
    Hand_L       = "Left Hand",
    Hand_R       = "Right Hand",
}

-- ---------------------------------------------------------------------------
-- Returns per-zone data for clothing items — used by the detail zone.
-- Each entry covers one BloodBodyPartType covered by the garment.
-- ---------------------------------------------------------------------------
local function getClothingZones(item)
    if not instanceof(item, "Clothing") then return {} end
    local T     = ZeD.T
    local zones = {}
    local parts = safeGet(item, "getCoveredParts")
    if not parts then return zones end

    local condMax  = safeGet(item, "getConditionMax") or 1
    local cond     = safeGet(item, "getCondition") or condMax
    local condR    = math.max(0, math.min(1, cond / condMax))
    local hasDirt  = safeGet(item, "hasDirt") and true or false
    local wetRaw   = safeGet(item, "getWetness") or 0
    local wetPct   = math.max(0, math.min(1, wetRaw / 100))

    for i = 0, parts:size() - 1 do
        local part    = parts:get(i)
        local partStr = tostring(part)
        local name    = ZONE_DISPLAY_NAMES[partStr] or partStr:gsub("_", " ")

        -- Hole status via getVisual():getHole(part)
        local visual    = safeGet(item, "getVisual")
        local holeCount = 0
        if visual then
            local ok, hc = pcall(function() return visual:getHole(part) end)
            if ok and hc then holeCount = hc end
        end
        local hasHole = holeCount > 0

        -- Patch material (nil when unpatched)
        local patchObj = safeGet(item, "getPatchType", part)
        local patchStr = patchObj and tostring(patchObj) or nil

        -- Blood level for this zone (0-100 scale from PZ)
        local bloodRaw = safeGet(item, "getBloodlevelForPart", part) or 0
        local bloodPct = math.max(0, math.min(1, bloodRaw / 100))

        -- Zone condition: torn+unpatched zones read as 0%
        local zoneR = (hasHole and not patchStr) and 0.0 or condR

        -- Condition fill color
        local condCol
        if zoneR > 0.6 then condCol = T.positive
        elseif zoneR > 0.3 then condCol = T.warning
        else condCol = T.danger
        end

        -- Condition fill segments (main + optional patch bonus)
        local fillSegs = {
            {ratio = zoneR, color = {r=condCol.r, g=condCol.g, b=condCol.b, a=0.55}}
        }
        if patchStr then
            local bonus
            if     patchStr:find("Leather") then bonus = ZeD.colorAlpha(T.matLeather, 0.35)
            elseif patchStr:find("Denim")   then bonus = ZeD.colorAlpha(T.matDenim, 0.35)
            else                                 bonus = ZeD.colorAlpha(T.matFabric, 0.12)
            end
            table.insert(fillSegs, {ratio = math.min(0.15, 1 - zoneR), color = bonus})
        end

        -- Flag (TORN / patch material name / WORN)
        local flagText, flagColorKey
        if hasHole and not patchStr then
            flagText = "TORN";  flagColorKey = "danger"
        elseif patchStr then
            local mat = patchStr:match("%.(.+)") or patchStr
            if     mat:find("Leather") then mat = "Leather"
            elseif mat:find("Denim")   then mat = "Denim"
            elseif mat:find("Sheets") or mat:find("Ripped") then mat = "Fabric"
            end
            flagText = mat;  flagColorKey = "textSec"
        elseif condR < 0.6 then
            flagText = "WORN";  flagColorKey = "warning"
        end

        -- Condition dock action icon key
        local condIconKey
        if hasHole and not patchStr then
            condIconKey = "fashion-004-needle"  -- needs repair
        elseif patchStr then
            condIconKey = "sewing--pliers"      -- can remove patch
        end

        table.insert(zones, {
            name         = name,
            part         = part,         -- BloodBodyPartType ref for dispatch
            zoneR        = zoneR,
            fillSegs     = fillSegs,
            flagText     = flagText,
            flagColorKey = flagColorKey,
            condIconKey  = condIconKey,
            bloodPct     = bloodPct,
            hasDirt      = hasDirt,
            wetPct       = wetPct,
        })
    end
    return zones
end

-- ---------------------------------------------------------------------------
-- ITEM-LEVEL SOIL: dirt + wet aren't per-zone in vanilla (only blood is). They
-- get a single right-aligned row ABOVE the per-zone list in the detail zone.
-- Hoisted above _calcBodyH and render so both can resolve the upvalues.
-- ---------------------------------------------------------------------------
local function buildItemSoilCfg(item)
    local hasDirt = safeGet(item, "hasDirt") and true or false
    local wetRaw  = safeGet(item, "getWetness") or 0
    local wetPct  = (wetRaw > 15) and math.floor(wetRaw) or nil  -- 15% threshold matches formatClothing wet rule
    if not hasDirt and not wetPct then return nil end
    return { dirt = hasDirt, wet = wetPct }
end

local function drawItemSoilRow(panel, x, y, w, soil)
    local T  = ZeD.T
    local M  = ZeD.Molecules
    local sp = T.sp
    local btnSz = T.iconSm + T.px(4)
    local rx = x + w   -- right cursor, grows leftward

    -- the item's soil as tags, right-aligned: the word (sentence case) after a
    -- square mark in the soil's colour (no tinted fills, no coloured words)
    local tagW = function(lbl)
        return ZeD.TM:MeasureStringX(T.fontF1, ZeD.Atoms.textCase(lbl)) + T.px(10) + T.px(6) + T.px(4)
    end
    local ty = y + math.floor((btnSz - T.px(16)) / 2)
    if soil.wet then
        local lbl = soil.wet .. "%"
        rx = rx - tagW(lbl)
        M.drawTag(panel, rx, ty, lbl, T.soiledWet or T.info)
        rx = rx - sp.xs
    end
    if soil.dirt then
        local lbl = ZeD.tr("Tooltip_clothing_dirty")
        rx = rx - tagW(lbl)
        M.drawTag(panel, rx, ty, lbl, T.soiledDirt or T.warning)
    end
    return btnSz
end

function ZeD_ItemCard:new(x, y, width, height, mode, playerNum)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self); self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.item      = nil
    o.mode      = mode or "drawer"
    o.playerNum = playerNum or 0
    o.pad = ZeD.T.sp.sm; o.colGap = ZeD.T.sp.sm; o.iconSz = ZeD.T.cardIconSz
    -- Action strip state: toggle buttons (left) + verb buttons (right)
    o.toggleHover  = nil;  o.toggleWasDown  = false;  o.toggleRects = {}
    o.verbHover    = nil;  o.verbWasDown    = false;  o.verbRects   = {}
    o._verbDefs    = {}
    -- Fold state (per-type disclosure toggles, persisted via modData)
    o._foldStates    = {}        -- {clothing_zones=bool, food_nutrition=bool, food_ingredients=bool}
    o._foldHitRects  = {}        -- rebuilt each frame: {x,y,w,h,key}
    o._headH         = 0         -- cached sticky head height
    o._zoneDockRects = {}        -- zone dock button hit rects (clothing disclosure)
    o._foldWasDown   = false     -- mouse-was-down for fold toggle click-on-release
    o._zoneDockWasDown = false   -- mouse-was-down for zone dock click-on-release
    o._nameY         = 0         -- cached from render for prerender positioning
    -- Scroll state (drawer mode — content can exceed available height)
    o._scrollPixels  = 0
    o._contentH      = 0         -- full content height from calcHeight()
    o._sb            = nil       -- ZeD_ScrollbarState, created in initialise
    return o
end

function ZeD_ItemCard:initialise()
    ISPanel.initialise(self)

    self:_loadFoldStates()

    -- Scrollbar (both modes — content can exceed available height)
    local sb = ZeD_ScrollbarState:new()
    sb.visible = false
    sb.reserveBottom = 0
    local cardRef = self
    sb.onScroll = function(pos)
        local maxScroll = math.max(0, cardRef._contentH - (cardRef:getHeight() - cardRef._headH))
        cardRef._scrollPixels = math.floor(pos * maxScroll)
    end
    self._sb = sb
end

-- Called when a structural dock button is clicked.
-- Builds and queues the appropriate timed action for this player + zone.
function ZeD_ItemCard:_onZonePress(zoneIdx, zone, rect)
    if not self.item or not zone or not zone.dock then return end
    local player = getSpecificPlayer(self.playerNum)
    if not player then return end
    local item = self.item

    -- Determine which part this zone corresponds to
    local parts = safeGet(item, "getCoveredParts")
    if not parts or zoneIdx > parts:size() then return end
    local part = parts:get(zoneIdx - 1)  -- Java 0-indexed

    -- Oct 15 2026 (Inspect routed here, Overrides/Garment.lua): the dock opens
    -- vanilla's own tailoring choices for the part (which fabric, patch every
    -- hole, remove one patch or all), in the ZeD list under the dock. The
    -- one-press repair below stays as the fallback.
    if ZeD.Garment and ZeD.Garment.tailorMenu then
        local x = rect and rect.x or (self:getAbsoluteX() + math.floor(self:getWidth() / 2))
        local y = rect and (rect.y + rect.h) or self:getAbsoluteY()
        local ok, err = pcall(ZeD.Garment.tailorMenu, player, item, part, x, y)
        if ok then return end
        print("[ZeD] ItemCard: tailoring list failed, one-press repair: " .. tostring(err))
    end

    local visual   = safeGet(item, "getVisual")
    local holeCount = 0
    if visual then
        local ok, hc = pcall(function() return visual:getHole(part) end)
        if ok and hc then holeCount = hc end
    end
    local hasHole  = holeCount > 0
    local patchObj = safeGet(item, "getPatchType", part)

    if hasHole and not patchObj then
        -- Repair hole — find materials via shared helper
        local needle, thread, fabric = findClothingMaterials(player)
        if needle then
            ISTimedActionQueue.add(ISRepairClothing:new(player, item, part, fabric, thread, needle))
        end
    elseif patchObj then
        -- Remove patch — needs needle only
        local inv    = player:getInventory()
        local needle = inv:getFirstTagRecurse(ItemTag.SEWING_NEEDLE)
                    or inv:getItemFromType("Needle", true, true)
        if needle then
            ISTimedActionQueue.add(ISRemovePatch:new(player, item, part, needle))
        end
    end
end
function ZeD_ItemCard:setItem(item)
    self.item = item
    self:_loadFoldStates()
    -- Reset scroll on item change
    self._scrollPixels = 0
    if self._sb then self._sb:setScrollPos(0) end
    -- Cancel any in-progress rename when item swaps under us
    self:_cancelRename()
end

-- ---------------------------------------------------------------------------
-- RENAME - click the name row to open the rename prompt
-- ---------------------------------------------------------------------------

-- The name row opens the same prompt the item menu and the controller use
-- (ZeD.ItemMenu.rename: vanilla's text box, with its length check). The
-- card's inline text field cannot take typing, so it is no longer started.
function ZeD_ItemCard:_startRename()
    if not self.item then return end
    local ren = ZeD.ItemMenu and ZeD.ItemMenu.rename
    if ren then ren(self.item, self.playerNum or 0) end
end

function ZeD_ItemCard:_commitRename(text)
    if not self.item then self:_cancelRename(); return end
    text = text and tostring(text):match("^%s*(.-)%s*$") or ""
    local ok, cur = pcall(self.item.getName, self.item)
    -- Nothing typed, or the same name back: leave the item alone (no
    -- custom-name flag for an item nobody renamed).
    if text ~= "" and not (ok and cur == text) then
        if self.item.setName then pcall(self.item.setName, self.item, text) end
        if self.item.setCustomName then pcall(self.item.setCustomName, self.item, true) end
    end
    self:_cancelRename()
end

function ZeD_ItemCard:_cancelRename()
    self._renaming = false
    if self._renameInput then
        self._renameInput.focused = false
        self._renameInput:setVisible(false)
    end
end

-- ---------------------------------------------------------------------------
-- PROGRESS BAND CANCEL DISPATCH (S122 Phase B9)
-- Stops the active TimedAction for self.item via the action ref carried in
-- the ItemActionManager descriptor. ISBaseTimedAction.forceStop is the
-- canonical cancellation method; falls back to clearing the player's
-- entire queue if the action ref is missing or forceStop unavailable.
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_dispatchProgressCancel()
    if not self.item then return end
    local mgr = ZeD.ItemActionManager
    if not mgr then return end
    local active = mgr.getActiveAction(self.item)
    if not active then return end
    local action = active._action
    if action and action.forceStop then
        pcall(action.forceStop, action)
    elseif action and action.stop then
        pcall(action.stop, action)
    else
        -- Fallback: clear the player's entire queue. Bigger hammer but
        -- safe — the user explicitly clicked cancel.
        local p = getSpecificPlayer(self.playerNum or 0)
        if p and ISTimedActionQueue and ISTimedActionQueue.queues then
            local q = ISTimedActionQueue.getTimedActionQueue(p)  -- S123: queues are keyed by character, not playerNum
            -- S123: never forceStop queued-but-unstarted actions — vanilla's
            -- ISBaseTimedAction:forceStop indexes self.action, which is nil
            -- until start(), and throws. ISTimedActionQueue:clearQueue is the
            -- vanilla-safe way to drop the whole queue.
            if q and q.clearQueue then pcall(q.clearQueue, q) end
        end
    end
    -- Clear the manager's active state so the Band stops rendering even
    -- if the action's stop hook didn't fire (defensive)
    if mgr.notify then pcall(mgr.notify, self.item, "cancel") end
end

-- ---------------------------------------------------------------------------
-- HEADER VERB DISPATCH (S121 Phase B8)
-- Maps the v15 back-bar verb label to the corresponding vanilla
-- ISInventoryPaneContextMenu handler, then re-fires updateDrawer so the card
-- closes / re-opens correctly when item state changes (equip → unequip flips
-- sourceContext → cluster shifts).
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_dispatchHeaderVerb(label)
    local item = self.item
    if not item then return end
    local playerNum = self.playerNum or 0
    local player    = getSpecificPlayer(playerNum)
    if not player then return end
    -- A sleeping character takes no clicks (vanilla's inventory refuses them)
    if player.isAsleep and player:isAsleep() then return end
    -- A card whose item is gone must not send actions into a nil container
    if not item:getContainer() then return end

    -- Vanilla helpers expect an array of items (they run getActualItems on it
    -- to unpack stacks). Every name below was verified against the Oct 6 2026
    -- stable sources (S123). The pre-S123 names (onWear, onEquipPrimary,
    -- onEquipWeapon, OnReadBook, OnRead) never existed in stable, so the
    -- `if CM.x then` guards turned EQUIP and READ into silent no-ops.
    local items = {item}
    local CM = ISInventoryPaneContextMenu

    if label == "EQUIP" then
        if instanceof(item, "Clothing") then
            -- Wear: onWearItems handles hat/full-hat swaps and body-location
            -- de-duplication the same way the vanilla context menu does.
            if CM.onWearItems then CM.onWearItems(items, playerNum) end
        else
            -- Weapons and hand-held items. Two-handed weapons go to both
            -- hands (OnTwoHandsEquip) so the player gets no one-hand penalty;
            -- everything else goes primary. Both helpers extinguish a lit
            -- candle/lantern already in hand before swapping.
            local twoH = false
            if item.isTwoHandWeapon then
                local ok, v = pcall(item.isTwoHandWeapon, item)
                twoH = ok and v or false
            end
            if twoH and CM.OnTwoHandsEquip then
                CM.OnTwoHandsEquip(items, playerNum)
            elseif CM.OnPrimaryWeapon then
                CM.OnPrimaryWeapon(items, playerNum)
            elseif CM.equipWeapon then
                CM.equipWeapon(item, true, twoH, playerNum)
            end
        end
    elseif label == "UNEQUIP" then
        -- unequipItem extinguishes lit light sources first; fall back to the
        -- raw timed action if a future patch renames it.
        if CM.unequipItem then
            CM.unequipItem(item, playerNum)
        else
            ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
        end
    elseif label == "DROP" then
        if CM.onDropItems then CM.onDropItems(items, playerNum) end
    elseif label == "TAKE" then
        -- Floor items go through ZeD_WorldWindow.transferFromFloor (vanilla's transfer from the shared floor container).
        local cnt = item.getContainer and item:getContainer() or nil
        if ZeD_WorldWindow and ZeD_WorldWindow.transferFromFloor and cnt
           and cnt.getType and cnt:getType() == "floor" then
            ZeD_WorldWindow.transferFromFloor(player, item, player:getInventory())
        elseif CM.onGrabItems then
            CM.onGrabItems(items, playerNum)
        end
    elseif label == "EAT" then
        if CM.eatItem then
            CM.eatItem(item, 1, playerNum)
        end
    elseif label == "READ" then
        if instanceof(item, "Literature") then
            -- onLiteratureItems applies the illiterate / skill-level / tag
            -- guards, then calls readItem (transfer if needed + ISReadABook).
            if CM.onLiteratureItems then
                CM.onLiteratureItems(items, playerNum)
            elseif CM.readItem then
                CM.readItem(item, playerNum)
            end
        end
    elseif label == "USE" then
        -- Drainable / generic — fall through to contextual double-click
        local stub = {player = playerNum}
        if ISInventoryPane and ISInventoryPane.doContextualDblClick then
            ISInventoryPane.doContextualDblClick(stub, item)
        end
    -- Oct 19 2026 (the single-path audit): verbs only the context menu had
    elseif label == "DRINK" then
        if CM.onDrinkFluid then CM.onDrinkFluid(item, 1, player, nil, item) end
    elseif label == "WEAR" then
        if CM.onWearItems then CM.onWearItems(items, playerNum) end
    elseif label == "OFF HAND" then
        if CM.OnSecondWeapon then CM.OnSecondWeapon(items, playerNum) end
    elseif label == "MORE" then
        -- the item's whole context menu (ZeD's look, the player's choice of
        -- strip or list), opened under the MORE button
        local x, y = getMouseX(), getMouseY()
        local hv, rects = self._lastHeaderVerbs, self._backBarRects
        for i, v in ipairs(hv or {}) do
            local r = rects and rects.verbs and rects.verbs[i]
            if v.isMore and r then x, y = self:getAbsoluteX() + r.x, self:getAbsoluteY() + r.y + r.h end
        end
        local inv = player:getInventory()
        local mine = inv and item.getContainer and item:getContainer() and inv:containsRecursive(item) or false
        CM.createMenu(playerNum, mine, items, x, y)
    end
end

-- ---------------------------------------------------------------------------
-- LIVE SOURCE CONTEXT (S123)
-- The window stamps self.sourceContext once, at selection time. After a verb
-- fires (EQUIP → item now worn; TAKE → item now in the backpack) the stamp is
-- stale, so the verb cluster kept showing the verb that was just used until
-- the user re-selected the row. This re-derives the context from the item's
-- actual state each render. The stored stamp is only the fallback for items
-- whose state can't be read (world items with no container, nil item).
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_effectiveContext()
    local ctx  = self.sourceContext or "inventory"
    local item = self.item
    if not item then return ctx end
    local player = getSpecificPlayer(self.playerNum or 0)
    if not player then return ctx end

    -- Worn or held wins regardless of which container the item lives in.
    if item.isEquipped then
        local ok, eq = pcall(item.isEquipped, item)
        if ok and eq then return "equipped" end
    end

    local okC, cnt = pcall(function() return item:getContainer() end)
    if not okC or not cnt then return ctx end

    -- Java object identity survives the Kahlua bridge; vanilla relies on the
    -- same comparison (item:getContainer() ~= playerObj:getInventory()).
    if cnt == player:getInventory() then return "inventory" end

    local okT, t = pcall(function() return cnt:getType() end)
    if okT and t == "floor" then return "ground" end
    return "container"
end

-- ---------------------------------------------------------------------------
-- FOLD STATE: per-type disclosure toggles, persisted via player modData
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_loadFoldStates()
    local player = getSpecificPlayer(self.playerNum)
    if not player then self._foldStates = {}; return end
    local md = player:getModData()
    -- Detail zones default OPEN on first encounter — the drawer card IS the
    -- inspector (per design: no separate inspect window). Once the user toggles,
    -- their preference persists via modData.
    local function foldDefault(key, def)
        local v = md["ZeD_fold_" .. key]
        if v == nil then return def end
        return v
    end
    self._foldStates = {
        clothing_zones     = foldDefault("clothing_zones",   true),
        food_nutrition     = foldDefault("food_nutrition",   true),
        food_ingredients   = foldDefault("food_ingredients", false),
    }
end

function ZeD_ItemCard:_toggleFold(key)
    local newVal = not self._foldStates[key]
    self._foldStates[key] = newVal
    local player = getSpecificPlayer(self.playerNum)
    if player then
        player:getModData()["ZeD_fold_" .. key] = newVal
    end
    -- Clamp scroll if body shrank
    local bodyH = self:_calcBodyH()
    local viewH = self:getHeight() - self._headH
    local maxScroll = math.max(0, bodyH - viewH)
    if self._scrollPixels > maxScroll then
        self._scrollPixels = maxScroll
        if self._sb then self._sb:setScrollPos(maxScroll > 0 and (self._scrollPixels / maxScroll) or 0) end
    end
end

-- ---------------------------------------------------------------------------
-- PRIMARY BAR: the single most-important bar for the sticky head
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_getPrimaryBar(item)
    local bars = getBarsForItem(item)
    if #bars > 0 then return bars[1] end
    return nil
end

-- ---------------------------------------------------------------------------
-- HEIGHT CALCULATIONS: sticky head + scrollable body
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_calcHeadH()
    if not self.item then return 0 end
    local T        = ZeD.T
    local sp       = T.sp
    local statRowH = getStatRowH()
    local headH    = ZeD.TM:getFontHeight(T.fontF4)
    local btnSz    = T.iconSm + T.px(4)
    local sbW      = (self._sb and self._sb.visible) and self._sb.width or 0
    local innerW   = math.max(T.px(80), self:getWidth() - self.pad * 2 - sbW)

    -- Row 1: icon + name side by side
    local nameGap  = sp.sm  -- gap between icon and name
    local nameMaxW = innerW - self.iconSz - nameGap
    local displayName = safeGet(self.item, "getDisplayName") or "???"
    local nameLines   = wrapText(displayName, T.fontF4, nameMaxW)
    local nameH = headH * #nameLines
    local row1H = math.max(self.iconSz, nameH)

    -- Row 2: primary bar — label+% on line 1, fill bar on line 2
    local primaryBar = self:_getPrimaryBar(self.item)
    local row2H = primaryBar and (statRowH + sp.cardAfterBody + T.fillBarH) or 0

    -- Row 3: action strip
    local row3H = sp.sm + btnSz + sp.sm

    return self.pad + row1H + sp.cardAfterHead + row2H + sp.cardAfterBody + row3H + T.px(1)  -- +1 for bottom border
end

function ZeD_ItemCard:_calcBodyH()
    if not self.item then return 0 end
    local T        = ZeD.T
    local sp       = T.sp
    local statRowH = getStatRowH()
    local bodyH    = ZeD.TM:getFontHeight(T.fontF2)
    local secH     = ZeD.TM:getFontHeight(T.fontF1)
    local headH    = ZeD.TM:getFontHeight(T.fontF4)
    local btnSz    = T.iconSm + T.px(4)
    local grooveH  = T.px(2)
    local item     = self.item
    local cat      = getItemCategory(item)

    local h = sp.cardAfterHead  -- after sticky head border

    -- Badges
    local alerts = getStatusAlerts(item)
    if #alerts > 0 then
        local badgeH = ZeD.TM:getFontHeight(T.fontF3) + sp.badgePadY * 2
        h = h + badgeH + T.px(6)
    end

    -- Stats
    local stats = getStatsForItem(item)
    h = h + statRowH * #stats

    -- Category + Weight (labels)
    h = h + statRowH * 2  -- category + weight

    -- Divider
    h = h + sp.cardAfterBody + T.px(1) + sp.cardAfterHead  -- after body, 1px divider, after heading

    -- Secondary bars (all bars except primary which is in head)
    -- Two-line layout: label+% row, then fill bar row
    local allBars = getBarsForItem(item)
    if #allBars > 1 then
        for i = 2, #allBars do
            h = h + statRowH + sp.cardAfterBody + T.fillBarH
            if i < #allBars then h = h + sp.cardAfterLabel end
        end
        h = h + sp.cardAfterBody
    end

    -- Disclosures
    if cat == "Clothing" then
        h = h + T.rowH  -- section header
        if self._foldStates.clothing_zones then
            -- Item-level soil row (dirt + wet) sits above the per-zone list.
            if buildItemSoilCfg(item) then h = h + btnSz end
            local zones = getClothingZones(item)
            local topRowH = math.max(bodyH + T.px(4), T.fillBarH + T.px(4), btnSz)
            for i, zone in ipairs(zones) do
                if i > 1 then h = h + grooveH end
                h = h + topRowH
                -- Bottom line (dock/soiled) if present — per-zone soiled = blood only
                local hasSoiled = zone.bloodPct and zone.bloodPct > 0
                local hasDock = zone.condIconKey or zone.flagText
                if hasDock or hasSoiled then h = h + btnSz end
            end
        end
    elseif cat == "Food" then
        local nutrition   = getNutritionForItem(item)
        local ingredients = getIngredientsForItem(item)

        -- Nutrition disclosure
        if #nutrition > 0 then
            h = h + T.rowH  -- section header
            if self._foldStates.food_nutrition then
                local thickRule = T.line(2); local thinRule = T.hair   -- as drawFactsRuleThick / Thin draw them
                h = h + sp.cardBeforeHead + headH + sp.cardAfterHead + thickRule + sp.cardAfterHead
                for i = 1, #nutrition do
                    h = h + statRowH
                    if i < #nutrition and not nutrition[i+1].sub then
                        h = h + thinRule + sp.cardAfterBody
                    end
                end
                h = h + sp.cardAfterBody
            end
        end

        -- Ingredients disclosure
        if #ingredients > 0 then
            h = h + T.rowH  -- section header
            if self._foldStates.food_ingredients then
                local ingrLineH = secH + T.px(2)
                local labelStr  = "INGREDIENTS: "
                local names = {}
                for _, ing in ipairs(ingredients) do names[#names + 1] = ing.name end
                local fullStr   = labelStr .. table.concat(names, ", ")
                local innerEstW = self:getWidth() - self.pad * 4
                if innerEstW < T.px(50) then innerEstW = T.px(200) end
                local fullW     = ZeD.TM:MeasureStringX(T.fontF1, fullStr)
                local lineCount = math.max(1, math.ceil(fullW / innerEstW))
                h = h + sp.cardAfterHead + ingrLineH * lineCount + sp.cardAfterLabel + statRowH
            end
        end
    end

    h = h + self.pad + T.line(T.borderW)  -- bottom padding (borderW is design units: that many hairlines)
    return h
end

-- ---------------------------------------------------------------------------
-- THE POINTER: action strip interaction (toggle buttons + verb buttons, both modes)
-- These controls poll the raw mouse. The engine runs update() only every 100 ms
-- (42.22), so a click that fell between two updates did nothing (Oct 30 2026, the
-- director: "clicking back on an item card does nothing"): they are polled at the
-- end of every frame drawn (render), against the rects that frame stamped.
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:update()
    ISPanel.update(self)
end

function ZeD_ItemCard:_pointer()
    if not self.item then return end

    -- S121 (Phase B8): back-bar click dispatch. _backBarRects is stamped by
    -- renderBody each frame: .back = back-arrow rect, .verbs[i] = header
    -- verb rects (right-aligned, drawn right-to-left so [1] is leftmost
    -- after primary). Verb labels come from ZeD.ItemCard.headerVerbsForContext.
    do
        local mxAbs   = getMouseX()
        local myAbs   = getMouseY()
        local downAbs = isMouseButtonDown(0)
        local ax, ay  = self:getAbsoluteX(), self:getAbsoluteY()
        local rects   = self._backBarRects

        local function inAbsRect(r)
            local rx = r.x + ax
            local ry = r.y + ay
            return mxAbs >= rx and mxAbs < rx + r.w
               and myAbs >= ry and myAbs < ry + r.h
        end

        -- Back arrow → onBackClick callback installed by parent surface
        if rects and rects.back then
            local inBack = inAbsRect(rects.back)
            if self._backWasDown and not downAbs and inBack and self.onBackClick then
                self:onBackClick()
            end
            self._backWasDown = downAbs and inBack or false
        end

        -- Name row click -> the rename prompt
        if self._nameRowRect then
            local nr = self._nameRowRect
            local rx, ry = nr.x + ax, nr.y + ay
            local inName = mxAbs >= rx and mxAbs < rx + nr.w
                       and myAbs >= ry and myAbs < ry + nr.h
            if self._nameWasDown and not downAbs and inName then
                self:_startRename()
            end
            self._nameWasDown = downAbs and inName or false
        end

        -- Progress Band cancel button → forceStop the active action
        if self._cancelRect then
            local cr = self._cancelRect
            local inCancel = mxAbs >= cr.x and mxAbs < cr.x + cr.w
                         and myAbs >= cr.y and myAbs < cr.y + cr.h
            if self._cancelWasDown and not downAbs and inCancel then
                self:_dispatchProgressCancel()
            end
            self._cancelWasDown = downAbs and inCancel or false
        end

        -- Header verbs → vanilla PZ contextual actions keyed by label
        if rects and rects.verbs and self.item then
            local hover = nil
            for i, vr in ipairs(rects.verbs) do
                if inAbsRect(vr) then hover = i; break end
            end
            if self._headerVerbWasDown and not downAbs and hover then
                local hv = self._lastHeaderVerbs and self._lastHeaderVerbs[hover]
                local label = hv and (hv.id or hv.label)
                if label then self:_dispatchHeaderVerb(label) end
            end
            self._headerVerbWasDown = downAbs and (hover ~= nil) or false
        end
    end

    -- Toggle button interaction
    self.toggleHover, self.toggleWasDown = ZeD.Molecules.updateActionStrip(
        self.toggleRects, ZeD.ActionStrip.TOGGLE_DEFS,
        self.item, self.toggleHover, self.toggleWasDown, self.playerNum
    )

    -- Verb button interaction
    local mx   = getMouseX()
    local my   = getMouseY()
    local down = isMouseButtonDown(0)
    local newVerbHover = nil
    for i, rect in ipairs(self.verbRects) do
        if mx >= rect.x and mx < rect.x + rect.w and my >= rect.y and my < rect.y + rect.h then
            newVerbHover = i
            break
        end
    end
    -- Click on release — dispatch verb action via VERB_DISPATCH table
    if self.verbWasDown and not down and newVerbHover then
        local def = self._verbDefs[newVerbHover]
        if def and def.active then
            local handler = VERB_DISPATCH[def.key]
            if handler then handler(self, def) end
        end
    end
    self.verbHover    = newVerbHover
    self.verbWasDown  = down and (newVerbHover ~= nil)

    -- The mark strip's Lists button (loadouts B3): released on it, the lists' pop-up
    do
        local r = self._listsRect
        local inL = r and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h or false
        if self._listsWasDown and not down and inL then self:openListsPopup() end
        self._listsWasDown = down and inL
    end

    -- Fold toggle click detection (disclosure headers in scrollable body)
    local bodyTop = self:getAbsoluteY() + self._headH
    local bodyBot = self:getAbsoluteY() + self:getHeight() - (self._verbStripResvH or 0)

    -- The folded row (opens / folds) and, while open, its greyed care verbs
    -- (a press: the character says what the verb needs). Absolute rects.
    do
        local hitMore = nil
        local mr = self._moreRowRect
        if mr and my >= bodyTop and my < bodyBot and mx >= mr.x and mx < mr.x + mr.w and my >= mr.y and my < mr.y + mr.h then
            hitMore = 0
        end
        for i, r in ipairs(self._moreVerbRects or {}) do
            if my >= bodyTop and my < bodyBot and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h then hitMore = i end
        end
        if self._moreWasDown and not down and hitMore ~= nil then
            if hitMore == 0 then
                self:_toggleMoreRow()
            else
                local hv = self._moreVerbs and self._moreVerbs[hitMore]
                local handler = hv and VERB_DISPATCH[hv.key]
                if handler then handler(self, hv) end
            end
        end
        self._moreWasDown = down and (hitMore ~= nil)
    end
    for _, rect in ipairs(self._foldHitRects) do
        local absRectY = rect.y
        -- Only clickable if visible in viewport
        if absRectY + rect.h > bodyTop and absRectY < bodyBot then
            local inRect = mx >= rect.x and mx < rect.x + rect.w
                       and my >= absRectY and my < absRectY + rect.h
            if self._foldWasDown and not down and inRect then
                self:_toggleFold(rect.key)
            end
        end
    end
    self._foldWasDown = down

    -- Zone dock click detection (clothing disclosure, repair/pad buttons)
    for _, rect in ipairs(self._zoneDockRects) do
        local absRectY = rect.y
        if absRectY + rect.h > bodyTop and absRectY < bodyBot then
            local inRect = mx >= rect.x and mx < rect.x + rect.w
                       and my >= absRectY and my < absRectY + rect.h
            if self._zoneDockWasDown and not down and inRect then
                self:_onZonePress(rect.zoneIdx, rect.zone, rect)
            end
        end
    end
    self._zoneDockWasDown = down

    -- Scrollbar hover/drag
    if self._sb and self._sb.visible then
        local sbMx = mx - self:getAbsoluteX()
        local sbMy = my - self:getAbsoluteY()
        local inSb = sbMx >= self._sb.x and sbMx < self._sb.x + self._sb.width
                     and sbMy >= self._sb.y and sbMy < self:getHeight()
        if inSb then
            self._sb:handleMouseMove(sbMy - self._sb.y)
        elseif not self._sb.dragging then
            self._sb.upHover = false
            self._sb.downHover = false
            self._sb.thumbHover = false
        end
        if self._sb.dragging then
            self._sb:handleMouseMove(sbMy - self._sb.y)
        end
    end
end

function ZeD_ItemCard:prerender()
    local T = ZeD.T
    -- Safety: skip layout at tiny widths (drawer animation in progress)
    if self:getWidth() < T.px(80) then return end
    -- Sync padding from token every frame so text size toggle takes effect immediately.
    self.pad    = ZeD.T.sp.sm
    self.colGap = ZeD.T.sp.sm
    self.iconSz = ZeD.T.cardIconSz

    -- S121: in drawer mode, the card always fills its parent (the itemDrawer
    -- panel sized to win body). renderBody stamps `self._headH` and
    -- `self._contentH` based on actual v15 chrome + body composition; the
    -- scrollbar is configured against THOSE values one frame later. Legacy
    -- _calcHeadH / _calcBodyH (pre-S121 ItemCard layout assumptions) is
    -- skipped here — calling it would shrink the card to the OLD layout's
    -- content height and clip Defense Facts + lower zone groups.
    if self.item then
        if self.mode == "drawer" and self.parent then
            -- _fillH: a host that keeps a strip under the card (the Equip tab's layer strip)
            local parentH = self._fillH or self.parent:getHeight()
            if self.height ~= parentH then self:setHeight(parentH) end
        else
            -- Inspect / non-drawer mode: rough sizing via legacy calc still
            -- works since prerender runs before render and the legacy values
            -- are within ballpark of the new layout for non-clothing items.
            self._headH = self:_calcHeadH()
            local bodyContentH = self:_calcBodyH()
            self._contentH = bodyContentH
            local fullH = self._headH + bodyContentH
            if fullH ~= self.height then self:setHeight(fullH) end
        end

        -- Scrollbar setup uses values stamped by the previous frame's
        -- renderBody: self._contentH (from organism) vs self._headH
        -- (chrome height incl. back-bar + name row + flag strip + progress
        -- band). Verb strip footer is reserved separately — scrollbar ends
        -- above it so the thumb never runs behind WASH/REPAIR/PAD.
        if self._sb then
            local T = ZeD.T
            local newH        = self:getHeight()
            local headH       = self._headH or 0
            local contentH    = self._contentH or 0
            local verbResv    = self._verbStripResvH or 0
            local viewH       = newH - headH - verbResv
            local needsScroll = contentH > viewH and viewH > 0
            self._sb.visible = needsScroll
            if needsScroll then
                self._sb.width  = T.sp.scrollbarW
                self._sb.arrowH = T.sp.scrollbarW
                self._sb.x      = self:getWidth() - T.sp.scrollbarW
                self._sb.y      = headH
                self._sb.height = viewH
                self._sb:setBarSize(viewH / contentH)
                local maxScroll = contentH - viewH
                if self._scrollPixels > maxScroll then self._scrollPixels = maxScroll end
            else
                self._scrollPixels = 0
                self._sb:setScrollPos(0)
            end
        end
    end

    -- Card bg is transparent — the drawer surface provides the full-height background
    self.backgroundColor.a = 0
    -- No border of its own: the lines around the card are the window's (the
    -- waterfall's edge, the pane divider, the help line's line, the frame).
    -- A card laid over a tab's content draws that one edge (drawOverlayEdge).
    self.borderColor.a = 0
    ISPanel.prerender(self)
end

--- The structure line on the edge where the card lies over other content: the
--- host sets card.overlayEdge = "left" / "right" (nil: none; the window's own
--- lines bound the card). Drawn last in the card's render, from top to bottom.
function ZeD_ItemCard:drawOverlayEdge()
    local edge = self.overlayEdge
    if edge ~= "left" and edge ~= "right" then return end
    local T = ZeD.T
    local bs = T.borderS
    local x = (edge == "left") and 0 or (self:getWidth() - T.px(1))
    self:drawRect(x, 0, T.px(1), self:getHeight(), bs.a or 1, bs.r, bs.g, bs.b)
end

-- ---------------------------------------------------------------------------
-- RENDER HELPER: build M16 zone configs from getClothingZones() output
-- ---------------------------------------------------------------------------
local function buildZoneConfigs(item)
    local T    = ZeD.T
    local zones  = getClothingZones(item)
    local cfgs   = {}
    for _, zone in ipairs(zones) do
        -- Pristine + clean zones get NO dock — drawZoneRow will collapse the
        -- bottom row entirely (no "OK" filler row). Only build a dock when there
        -- IS something to communicate (TORN/WORN flag or active patch).
        local dock = nil
        if zone.condIconKey or zone.flagText then
            local dockFlag  = zone.flagText or "-"
            local dockColor = T[zone.flagColorKey] or T.textSec
            if zone.flagText == "Leather" then dockColor = T.matLeather
            elseif zone.flagText == "Denim" then dockColor = T.matDenim
            elseif zone.flagText == "Fabric" then dockColor = T.matFabric end
            -- (the dock's mark is drawn by ItemCardOrganism._drawDockCell from the zone's action)
            local dockState = (not zone.condIconKey) and "grey" or "active"
            dock = { flag = dockFlag, color = dockColor, state = dockState }
        end
        -- Per-zone soiled flags: BLOOD ONLY. Dirt + wet are item-level (vanilla
        -- exposes only getBloodlevelForPart per zone); they render as a single
        -- item-level row above the per-zone list — see drawItemSoilRow.
        local soiledCfg = nil
        if zone.bloodPct > 0 then
            soiledCfg = { blood = math.floor(zone.bloodPct * 100) }
        end
        -- Action key derived from condIconKey so render-time dispatch + greying
        -- doesn't have to re-walk getClothingZones (avoids double Q119 pcall log).
        local actionKey = nil
        if     zone.condIconKey == "fashion-004-needle" then actionKey = "repair"
        elseif zone.condIconKey == "sewing--pliers"     then actionKey = "remove-patch"
        end
        table.insert(cfgs, {
            name = zone.name, pct = math.floor(zone.zoneR * 100),
            bar = true, dock = dock, soiled = soiledCfg, action = actionKey,
        })
    end
    return cfgs
end

-- ===========================================================================
-- RENDER: three-phase pipeline — sticky head → stenciled body → scrollbar
-- ===========================================================================
function ZeD_ItemCard:render()
    local T = ZeD.T
    if not self.item then return end
    if self:getWidth() < T.px(80) then return end
    -- S121: delegate body composition to ItemCardOrganism (renderBody method).
    -- The new organism handles back-bar, flag strip, progress band, body
    -- (clothing zones / facts dispatch), and maintenance verb strip per
    -- v13/v15/v16 spec. Scrollbar paint stays here so it overlays.
    self:renderBody({sourceContext = self:_effectiveContext()})
    if self._sb and self._sb.visible then self._sb:draw(self) end
    self:_pointer()   -- (every frame drawn: update() runs only every 100 ms)
end


-- ---------------------------------------------------------------------------
-- SCROLL HANDLERS (both modes — body content below sticky head)
-- ---------------------------------------------------------------------------

function ZeD_ItemCard:onMouseWheel(del)
    if self._sb and self._sb.visible then
        self._sb:handleMouseWheel(del)
        return true
    end
    return false
end

function ZeD_ItemCard:onMouseDown(x, y)
    if self._sb and self._sb.visible and x >= self._sb.x then
        self._sb:handleMouseDown(y - self._sb.y)
        return true
    end
    -- Consume all clicks when card has an item — prevent bleed-through to tabs
    if self.item then return true end
    return false
end

function ZeD_ItemCard:onMouseUp(x, y)
    if self._sb then self._sb:handleMouseUp() end
end

function ZeD_ItemCard:onMouseUpOutside(x, y)
    if self._sb then self._sb:handleMouseUp() end
end

function ZeD_ItemCard:calcHeight()
    local T = ZeD.T
    if not self.item then return T.px(100) end
    if self:getWidth() < T.px(80) then return T.px(100) end
    return self:_calcHeadH() + self:_calcBodyH()
end

-- ---------------------------------------------------------------------------
-- GAMEPAD RING API (S99)
-- Exposes action strip buttons as focusable elements + disclosure scroll.
-- Window reads these into w._focusRing[charItemCard].elements each frame.
-- Rects come from the previous frame's render (toggleRects / verbRects);
-- bounds are at most 1 frame stale, acceptable for cone nav.
-- ---------------------------------------------------------------------------

-- Return focusable elements for the card's action strip, left-to-right:
-- FAV, PROTECT, UNWANTED, then verbs (repair_all/pad_all/repair/sharpen/etc.).
-- Element 1 (FAV) is the default landing per design.
function ZeD_ItemCard:getActionStripElements()
    if not self.item then return {} end
    local els  = {}
    local item = self.item
    local card = self

    -- S122 (B9): Progress Band cancel as a leading focusable. Only present
    -- when an action is active (Manager.getActiveAction != nil). Lands as
    -- the first ring element when armed so X press hits it without ring nav.
    -- Every rect here is ABSOLUTE, like toggleRects / verbRects / the zone
    -- docks; the window converts them to drawer-local.
    if self._cancelRect and ZeD.ItemActionManager
       and ZeD.ItemActionManager.getActiveAction
       and ZeD.ItemActionManager.getActiveAction(item) then
        local cr = self._cancelRect
        local eid = "cancel_band"
        els[#els + 1] = {
            x = cr.x, y = cr.y, w = cr.w, h = cr.h,
            id = eid,
            onFocus    = function() card._gpFocusedBtnId = eid end,
            onActivate = function() card:_dispatchProgressCancel() end,
        }
    end

    -- Header verbs (Eat / Wear / Drop ...): the card's main actions. Back-bar
    -- rects are card-local (update() adds the origin), so lift them here.
    -- Oct 23 2026: they are the card's action strip (isStrip); the card's
    -- main button (the CTA: Eat, Take, Wear...) is isPrimary, where the
    -- controller lands when the card opens (else the first of them).
    local hb = self._backBarRects
    if hb and hb.verbs and self._lastHeaderVerbs then
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        local firstStrip, anyPrimary = nil, false
        for i, r in ipairs(hb.verbs) do
            local v = self._lastHeaderVerbs[i]
            if r and r.x and v and v.label then
                local eid, label = "hverb_" .. i, (v.id or v.label)
                els[#els + 1] = {
                    x = ax + r.x, y = ay + r.y, w = r.w, h = r.h,
                    id = eid,
                    isStrip = true,
                    isPrimary = v.primary and true or nil,
                    onFocus    = function() card._gpFocusedBtnId = eid end,
                    onActivate = function() card:_dispatchHeaderVerb(label) end,
                }
                firstStrip = firstStrip or els[#els]
                if v.primary then anyPrimary = true end
            end
        end
        if firstStrip and not anyPrimary then firstStrip.isPrimary = true end
    end

    -- The name row: A renames through the prompt (the controller keyboard
    -- types into its field; the card's inline field is mouse and keys only)
    local nr = self._nameRowRect
    if nr and nr.x and not self._renaming and ZeD.ItemMenu and ZeD.ItemMenu.rename then
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        els[#els + 1] = {
            x = ax + nr.x, y = ay + nr.y, w = nr.w, h = nr.h,
            id = "name_row",
            onFocus    = function() card._gpFocusedBtnId = "name_row" end,
            onActivate = function() ZeD.ItemMenu.rename(item, card.playerNum or 0) end,
        }
    end

    -- The folded row of care verbs the character can't do yet (A opens or
    -- folds it), then, while open, each of them greyed (A: the character says
    -- what it needs). Rects are absolute, stamped by renderBody.
    local mr = self._moreRowRect
    if mr and mr.x then
        els[#els + 1] = {
            x = mr.x, y = mr.y, w = mr.w, h = mr.h,
            id = "more_row",
            onFocus    = function() card._gpFocusedBtnId = "more_row" end,
            onActivate = function() card:_toggleMoreRow() end,
        }
        for i, hv in ipairs(self._moreVerbs or {}) do
            local r = self._moreVerbRects and self._moreVerbRects[i]
            if r then
                local eid, vkey = "more_" .. tostring(hv.key), hv.key
                els[#els + 1] = {
                    x = r.x, y = r.y, w = r.w, h = r.h,
                    id = eid,
                    onFocus    = function() card._gpFocusedBtnId = eid end,
                    onActivate = function()
                        local handler = VERB_DISPATCH[vkey]
                        if handler then handler(card, hv) end
                    end,
                }
            end
        end
    end

    local DEFS = ZeD.ActionStrip.TOGGLE_DEFS
    for i, def in ipairs(DEFS) do
        local r = self.toggleRects and self.toggleRects[i]
        if r then
            local tkey = def.key
            local eid  = "toggle_" .. tkey
            els[#els + 1] = {
                x = r.x, y = r.y, w = r.w, h = r.h,
                id = eid,
                onFocus = function() card._gpFocusedBtnId = eid end,
                onActivate = function()
                    local cur = ZeD.ActionStrip.getState(item, tkey, card.playerNum)
                    ZeD.ActionStrip.setState(item, tkey, not cur, card.playerNum)
                end,
            }
        end
    end

    -- the Lists mark: A opens the lists' pop-up (it takes the pad; B closes it, back here)
    if self._listsRect then
        local r = self._listsRect
        els[#els + 1] = {
            x = r.x, y = r.y, w = r.w, h = r.h,
            id = "toggle_lists",
            onFocus = function() card._gpFocusedBtnId = "toggle_lists" end,
            onActivate = function() card:openListsPopup() end,
        }
    end

    for i, vdef in ipairs(self._verbDefs or {}) do
        local r = self.verbRects and self.verbRects[i]
        if r then
            local vkey    = vdef.key
            local vactive = vdef.active
            local eid     = "verb_" .. vkey
            els[#els + 1] = {
                x = r.x, y = r.y, w = r.w, h = r.h,
                id = eid,
                onFocus = function() card._gpFocusedBtnId = eid end,
                onActivate = function()
                    if not vactive then return end
                    local handler = VERB_DISPATCH[vkey]
                    if handler then handler(card, vdef) end
                end,
            }
        end
    end

    return els
end

-- Oct 23 2026 (director: "it is difficult navigate up to the strip"): the
-- card's D-pad, shared by both windows' card zones (zoneName). Up from any
-- control in the card goes straight to the action strip, onto its primary
-- button; on the strip, Up scrolls the card back up by a section. Down goes
-- to the next control below in the card; past the last one it scrolls the
-- card on by a section, so the whole card can be read. Left / Right return
-- false: the window's spatial move (along a row; off the card at its edge).
function ZeD_ItemCard:gpDpad(w, e, dir, zoneName)
    if dir == "left" or dir == "right" then return false end
    local F = ZeD.Input and ZeD.Input.Focus
    if dir == "up" then
        if e and not e.isStrip and F and F.focusWhere then
            if F.focusWhere(w, zoneName, function(x) return x.isPrimary end) then return true end
        end
        self:scrollToPrevDisclosure()
        return true
    end
    local z = F and F.getFocusedZone and F.getFocusedZone(w)
    local N = ZeD.SpatialNav
    if e and z and z.elements and N then
        for _, x in ipairs(z.elements) do
            if x ~= e and N.cost(e, x, "down") then return false end
        end
    end
    self:scrollToNextDisclosure()
    return true
end

-- Return focusable elements for the clothing detail zone's structural docks.
-- One element per zone whose dock is actionable (TORN with materials, or PATCHED
-- with needle). Greyed/pristine zones are skipped — they're not in _zoneDockRects.
-- Element id is "dock_<zoneIdx>" matching the render-side stamping.
function ZeD_ItemCard:getZoneDockElements()
    if not self.item then return {} end
    local els  = {}
    local card = self
    for _, rect in ipairs(self._zoneDockRects or {}) do
        local eid     = rect.id or ("dock_" .. rect.zoneIdx)
        local zIdx    = rect.zoneIdx
        local zone    = rect.zone
        els[#els + 1] = {
            x = rect.x, y = rect.y, w = rect.w, h = rect.h,
            id = eid,
            onFocus    = function() card._gpFocusedBtnId = eid end,
            onActivate = function() card:_onZonePress(zIdx, zone, rect) end,
        }
    end
    return els
end

--- The focus mark's opts for the card's element `id` when the controller is on
-- it: this card's window has the focus, the controller is in use
-- (Focus.liveZone), the focus is in the card's zone and on that element.
-- Both windows have a card (charItemCard / worldItemCard); the Equip tab's
-- lives in charTabContent (self._gpZone). Else nil.
local _cardFocus = {}
function ZeD_ItemCard:focusFor(id)
    if id == nil then return nil end
    -- The Equip tab's back key is a stop of the window's own, not a card button: it has
    -- no button id here, the window names it by its slot ("__card_back").
    local backStop = (id == "back" and self._gpZone ~= nil)
    if not backStop and self._gpFocusedBtnId ~= id then return nil end
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local w     = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow()
    local zone  = (w and Focus.liveZone) and Focus.liveZone(w) or nil
    if not zone then return nil end
    if self._gpZone then
        if zone.zone ~= self._gpZone then return nil end
        if w._gpFocusedEquipSlot ~= "__card_" .. tostring(id) then return nil end
    elseif zone.zone ~= "charItemCard" and zone.zone ~= "worldItemCard" then
        return nil
    end
    if not ZeD.Atoms.isAncestor(w, self) then return nil end
    _cardFocus.win, _cardFocus.zone = w, zone.zone
    return _cardFocus
end

--- The mark strip's Lists button: the loadouts and outfits by name, with checkboxes
-- (ZeD_ListsMenu.lua), dropped from the button's lower left
function ZeD_ItemCard:openListsPopup()
    local r = self._listsRect
    local LU = ZeD.ListsUI
    if not (r and LU and self.item) then return end
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
    LU.openPopup(self.playerNum or 0, self.item, r.x - ZeD.T.px(4), r.y + r.h + ZeD.T.px(4))
end

--- Open or fold the card's folded row (remembered per item type for the session)
function ZeD_ItemCard:_toggleMoreRow()
    if self._moreKey and ZeD.Disclose then ZeD.Disclose.toggle(self._moreKey) end
end

-- Return disclosure-header content-Y positions (section header top edges),
-- in render order. "Content-Y" = panel-local Y with _scrollPixels removed, so
-- scrollTo math is independent of current scroll position.
-- Empty list for items without disclosures (weapons, food with no nutrition,
-- non-clothing non-food categories).
function ZeD_ItemCard:getDisclosureYs()
    local ys = {}
    local ay = self:getAbsoluteY()
    local scrollOff = self._scrollPixels or 0
    for _, rect in ipairs(self._foldHitRects or {}) do
        local panelY   = rect.y - ay
        local contentY = panelY + scrollOff
        ys[#ys + 1] = contentY
    end
    return ys
end

-- Set scroll so the given content-Y is just below the sticky head (top of
-- visible body). Clamps to [0, maxScroll]. No-op when body fits without scrolling.
function ZeD_ItemCard:scrollToContentY(contentY)
    if not self._sb or not self._sb.visible then return end
    local viewH     = self:getHeight() - self._headH
    local maxScroll = math.max(0, self._contentH - viewH)
    if maxScroll <= 0 then return end
    local target = contentY - self._headH
    if target < 0 then target = 0 end
    if target > maxScroll then target = maxScroll end
    self._scrollPixels = target
    self._sb:setScrollPos(target / maxScroll)
end

-- Jump scroll to the first disclosure header below the current scroll position.
-- No-op when already past the last disclosure, or when body isn't scrollable.
function ZeD_ItemCard:scrollToNextDisclosure()
    local ys = self:getDisclosureYs()
    if #ys == 0 then return end
    local cur = self._scrollPixels or 0
    for _, y in ipairs(ys) do
        local yScroll = y - self._headH
        if yScroll > cur + 1 then
            self:scrollToContentY(y)
            return
        end
    end
end

-- Jump scroll to the last disclosure header above the current scroll position,
-- or to the top if none. No-op when not scrollable.
function ZeD_ItemCard:scrollToPrevDisclosure()
    if not self._sb or not self._sb.visible then return end
    local ys = self:getDisclosureYs()
    local cur = self._scrollPixels or 0
    local targetY = nil
    for _, y in ipairs(ys) do
        local yScroll = y - self._headH
        if yScroll < cur - 1 then
            targetY = y
        else
            break
        end
    end
    if targetY then
        self:scrollToContentY(targetY)
    else
        self._scrollPixels = 0
        self._sb:setScrollPos(0)
    end
end

-- ===========================================================================
-- PUBLIC NAMESPACE: ZeD.ItemDetail
-- Shared by ZeD_ItemCard (drawer card for inv items) AND EquipmentTab
-- (selected-item view for equipped items). Equipment drawer IS the inspector
-- per design — no separate inspect window. Both render sites consume the same
-- detail-zone primitives.
-- ===========================================================================
ZeD                = ZeD or {}
ZeD.ItemDetail = ZeD.ItemDetail or {}

ZeD.ItemDetail.getZones        = getClothingZones
ZeD.ItemDetail.buildConfigs    = buildZoneConfigs
ZeD.ItemDetail.buildItemSoil   = buildItemSoilCfg
ZeD.ItemDetail.drawSoilRow     = drawItemSoilRow
ZeD.ItemDetail.findMaterials   = findClothingMaterials

-- One-call repair / remove-patch dispatch for a given item + part. Mirrors
-- ZeD_ItemCard:_onZonePress logic so EquipmentTab gets identical behavior.
function ZeD.ItemDetail.dispatchZoneAction(player, item, part, action)
    if not (player and item and part) then return end
    if action == "repair" then
        local needle, thread, fabric = findClothingMaterials(player)
        if needle then
            ISTimedActionQueue.add(ISRepairClothing:new(player, item, part, fabric, thread, needle))
        end
    elseif action == "remove-patch" then
        local inv = player:getInventory()
        local needle = inv:getFirstTagRecurse(ItemTag.SEWING_NEEDLE)
                    or inv:getItemFromType("Needle", true, true)
        if needle then
            ISTimedActionQueue.add(ISRemovePatch:new(player, item, part, needle))
        end
    end
end
