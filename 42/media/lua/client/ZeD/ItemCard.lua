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
    local a = getTextManager():getFontHeight(T.fontF1)
    local b = getTextManager():getFontHeight(T.fontF2)
    local tall = math.max(a, b)
    return tall + math.max(2, math.floor(tall * 0.15))
end

-- Returns a friendly subtype string for the Zone 1 stat anchor (e.g. body location for clothing).
local function getItemSubtype(item)
    if not item then return nil end
    if instanceof(item, "Clothing") then
        local bl = safeGet(item, "getBodyLocation")
        return (bl and tostring(bl) ~= "") and tostring(bl):gsub("_", " ") or nil
    end
    return nil
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

VERB_DISPATCH.repair_all = function(card)
    local player = getSpecificPlayer(card.playerNum)
    if not player then return end
    local item = card.item
    local parts = safeGet(item, "getCoveredParts")
    if not parts then return end
    local needle, thread, fabric = findClothingMaterials(player)
    if not needle then return end
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
    if not needle then return end
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
    -- No available fixer found — try first fixing/fixer anyway (vanilla shows greyed option)
    ISInventoryPaneContextMenu.onFix(item, card.playerNum, 0, 0)
end

VERB_DISPATCH.repair  = function(card) tryFixingManager(card) end
VERB_DISPATCH.sharpen = function(card) tryFixingManager(card) end

-- ---------------------------------------------------------------------------
-- Returns verb button defs for the action strip based on item type.
-- Each entry: {key, iconKey, active, tip}
-- active=false → greyed button (action unavailable)
-- ---------------------------------------------------------------------------
local function getVerbsForItem(item)
    if not item then return {} end
    local verbs = {}
    local cat = getItemCategory(item)
    if cat == "Clothing" then
        -- Need to call getClothingZones — defined below, so use a forward reference via pcall
        -- We recompute the minimal check here to avoid a forward-declaration dependency.
        local anyHole, anyUnpadded = false, false
        local parts = safeGet(item, "getCoveredParts")
        if parts then
            for i = 0, parts:size() - 1 do
                local part    = parts:get(i)
                local visual  = safeGet(item, "getVisual")
                local hc = 0
                if visual then
                    local ok, v = pcall(function() return visual:getHole(part) end)
                    if ok and v then hc = v end
                end
                local patch = safeGet(item, "getPatchType", part)
                if hc > 0 and not patch then anyHole = true end
                if not patch then anyUnpadded = true end
            end
        end
        table.insert(verbs, {key="repair_all", iconKey="fashion-004-needle",   active=anyHole,    tip="Repair all holes"})
        table.insert(verbs, {key="pad_all",    iconKey="housekeeping-057-pillow", active=anyUnpadded, tip="Pad all empty zones"})
    elseif cat == "Weapon" or cat == "Firearm" then
        local cond = safeGet(item, "getCondition")
        local mc   = safeGet(item, "getConditionMax")
        local full = cond and mc and mc > 0 and cond >= mc
        table.insert(verbs, {key="repair",  iconKey="home-improvements-033-hammer", active=not full, tip="Repair"})
        if cat == "Weapon" then
            table.insert(verbs, {key="sharpen", iconKey="home-improvements-047-saw", active=true, tip="Sharpen"})
        end
    end
    return verbs
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
    -- Rename state (click name text to rename, both modes)
    o._renaming      = false
    o._renameEntry   = nil       -- ISTextEntryBox child (created in initialise)
    o._nameHitRect   = nil       -- cached absolute hit-rect for name text
    o._nameHover     = false
    o._nameWasDown   = false
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

    -- Rename text entry (both modes — click name text to rename)
    local T = ZeD.T
    local entry = ISTextEntryBox:new("", 0, 0, 100, T.inputH)
    entry:initialise()
    entry:instantiate()
    entry:setMaxTextLength(28)
    entry:setVisible(false)
    self:addChild(entry)
    entry.onCommandEntered = function() self:_commitRename() end
    local cardRef = self
    entry.onKeyPress = function(_, key)
        if key == Keyboard.KEY_ESCAPE then cardRef:_cancelRename() end
    end
    self._renameEntry = entry

    -- Rename action buttons: Yes (save), No (cancel), Reset (revert to original)
    local btnYes = ZeD.Molecules.Button(0, 0, nil, "YES", self, function()
        cardRef:_commitRename()
    end)
    btnYes:initialise()
    btnYes:setVisible(false)
    self:addChild(btnYes)
    self._renameSaveBtn = btnYes

    local btnNo = ZeD.Molecules.Button(0, 0, nil, "NO", self, function()
        cardRef:_cancelRename()
    end)
    btnNo:initialise()
    btnNo:setVisible(false)
    self:addChild(btnNo)
    self._renameCancelBtn = btnNo

    local btnReset = ZeD.Molecules.Button(0, 0, nil, "RESET", self, function()
        if cardRef.item then
            local script = cardRef.item:getScriptItem()
            local origName = script and script:getDisplayName() or cardRef.item:getDisplayName()
            cardRef.item:setName(origName)
            cardRef.item:setCustomName(false)
        end
        cardRef:_cancelRename()
    end)
    btnReset:initialise()
    btnReset:setVisible(false)
    self:addChild(btnReset)
    self._renameResetBtn = btnReset
end

-- Called when a structural dock button is clicked.
-- Builds and queues the appropriate timed action for this player + zone.
function ZeD_ItemCard:_onZonePress(zoneIdx, zone)
    if not self.item or not zone or not zone.dock then return end
    local player = getSpecificPlayer(self.playerNum)
    if not player then return end
    local item = self.item

    -- Determine which part this zone corresponds to
    local parts = safeGet(item, "getCoveredParts")
    if not parts or zoneIdx > parts:size() then return end
    local part = parts:get(zoneIdx - 1)  -- Java 0-indexed

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
    if self._renaming then self:_cancelRename() end
    self.item = item
    self:_loadFoldStates()
    -- Reset scroll on item change
    self._scrollPixels = 0
    if self._sb then self._sb:setScrollPos(0) end
end

-- ---------------------------------------------------------------------------
-- RENAME: inline text entry (inspect mode only)
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_startRename()
    if not self.item or not self._renameEntry then return end
    self._renaming = true
    local name = safeGet(self.item, "getDisplayName") or ""
    self._renameEntry:setText(name)
    self._renameEntry:setVisible(true)
    self._renameEntry:focus()
end

function ZeD_ItemCard:_commitRename()
    if not self.item or not self._renameEntry then self:_cancelRename(); return end
    local newName = self._renameEntry:getText()
    if newName then newName = string.match(newName, "^%s*(.-)%s*$") end  -- trim
    if newName and #newName > 0 then
        self.item:setName(newName)
        self.item:setCustomName(true)
    end
    self:_cancelRename()
end

function ZeD_ItemCard:_cancelRename()
    self._renaming    = false
    self._nameHover   = false
    self._nameWasDown = false
    if self._renameEntry then
        self._renameEntry:setVisible(false)
        self._renameEntry:unfocus()
    end
end

-- ---------------------------------------------------------------------------
-- FOLD STATE: per-type disclosure toggles, persisted via player modData
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:_loadFoldStates()
    local player = getSpecificPlayer(self.playerNum)
    if not player then self._foldStates = {}; return end
    local md = player:getModData()
    self._foldStates = {
        clothing_zones     = md.ZeD_fold_clothing_zones or false,
        food_nutrition     = md.ZeD_fold_food_nutrition or false,
        food_ingredients   = md.ZeD_fold_food_ingredients or false,
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
    local bodyH    = getTextManager():getFontHeight(T.fontF2)
    local headH    = getTextManager():getFontHeight(T.fontF4)
    local btnSz    = T.iconSm + 4
    local sbW      = (self._sb and self._sb.visible) and self._sb.width or 0
    local innerW   = math.max(80, self:getWidth() - self.pad * 2 - sbW)

    -- Row 1: icon + name side by side
    local nameGap  = sp.sm  -- gap between icon and name
    local nameMaxW = innerW - self.iconSz - nameGap
    local nameH
    if self._renaming then
        nameH = T.inputH + sp.xs + T.buttonH + sp.xs
    else
        local displayName = safeGet(self.item, "getDisplayName") or "???"
        local nameLines   = wrapText(displayName, T.fontF4, nameMaxW)
        nameH = headH * #nameLines
        local hasCustomName = safeGet(self.item, "isCustomName") or false
        if hasCustomName then
            nameH = nameH + sp.textLineGap + getTextManager():getFontHeight(T.fontF1)
        end
    end
    local row1H = math.max(self.iconSz, nameH)

    -- Row 2: primary bar — label+% on line 1, fill bar on line 2
    local primaryBar = self:_getPrimaryBar(self.item)
    local row2H = primaryBar and (statRowH + sp.cardAfterBody + T.fillBarH) or 0

    -- Row 3: action strip
    local row3H = sp.sm + btnSz + sp.sm

    return self.pad + row1H + sp.cardAfterHead + row2H + sp.cardAfterBody + row3H + 1  -- +1 for bottom border
end

function ZeD_ItemCard:_calcBodyH()
    if not self.item then return 0 end
    local T        = ZeD.T
    local sp       = T.sp
    local statRowH = getStatRowH()
    local bodyH    = getTextManager():getFontHeight(T.fontF2)
    local secH     = getTextManager():getFontHeight(T.fontF1)
    local headH    = getTextManager():getFontHeight(T.fontF4)
    local btnSz    = T.iconSm + 4
    local grooveH  = 2
    local sbW      = (self._sb and self._sb.visible) and self._sb.width or 0
    local innerW   = math.max(80, self:getWidth() - self.pad * 2 - sbW)
    local item     = self.item
    local cat      = getItemCategory(item)

    local h = sp.cardAfterHead  -- after sticky head border

    -- Badges
    local alerts = getStatusAlerts(item)
    if #alerts > 0 then
        local badgeH = getTextManager():getFontHeight(T.fontF3) + sp.badgePadY * 2
        h = h + badgeH + 6
    end

    -- Stats
    local stats = getStatsForItem(item)
    h = h + statRowH * #stats

    -- Category + Weight (labels)
    h = h + statRowH * 2  -- category + weight

    -- Divider
    h = h + sp.cardAfterBody + 1 + sp.cardAfterHead  -- after body, 1px divider, after heading

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
            local zones = getClothingZones(item)
            local topRowH = math.max(bodyH + 4, T.fillBarH + 4, btnSz)
            for i, zone in ipairs(zones) do
                if i > 1 then h = h + grooveH end
                h = h + topRowH
                -- Bottom line (dock/soiled) if present
                local hasSoiled = (zone.bloodPct and zone.bloodPct > 0) or zone.hasDirt or (zone.wetPct and zone.wetPct > 0.15)
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
                local thickRule = 2; local thinRule = 1
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
                local ingrLineH = secH + 2
                local labelStr  = "INGREDIENTS: "
                local names = {}
                for _, ing in ipairs(ingredients) do names[#names + 1] = ing.name end
                local fullStr   = labelStr .. table.concat(names, ", ")
                local innerEstW = self:getWidth() - self.pad * 4
                if innerEstW < 50 then innerEstW = 200 end
                local fullW     = getTextManager():MeasureStringX(T.fontF1, fullStr)
                local lineCount = math.max(1, math.ceil(fullW / innerEstW))
                h = h + sp.cardAfterHead + ingrLineH * lineCount + sp.cardAfterLabel + statRowH
            end
        end
    end

    h = h + self.pad + T.borderW  -- bottom padding
    return h
end

-- ---------------------------------------------------------------------------
-- UPDATE: action strip interaction (toggle buttons + verb buttons, both modes)
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:update()
    ISPanel.update(self)
    if not self.item then return end

    -- Toggle button interaction
    self.toggleHover, self.toggleWasDown = ZeD.Molecules.updateActionStrip(
        self.toggleRects, ZeD.ActionStrip.TOGGLE_DEFS,
        self.item, self.toggleHover, self.toggleWasDown
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

    -- Rename interaction — click name text to rename (both modes)
    if not self._renaming then
        if self._nameHitRect then
            local r = self._nameHitRect
            local inName = mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h
            if self._nameWasDown and not down and inName then
                self:_startRename()
            end
            self._nameHover   = inName
            self._nameWasDown = down and inName
        end
    end
    -- Enter commits via entry.onCommandEntered, Escape via entry.onKeyPress

    -- Fold toggle click detection (disclosure headers in scrollable body)
    local bodyTop = self:getAbsoluteY() + self._headH
    local bodyBot = self:getAbsoluteY() + self:getHeight()
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
                self:_onZonePress(rect.zoneIdx, rect.zone)
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
    -- Safety: skip layout at tiny widths (drawer animation in progress)
    if self:getWidth() < 80 then return end
    -- Sync padding from token every frame so text size toggle takes effect immediately.
    self.pad    = ZeD.T.sp.sm
    self.colGap = ZeD.T.sp.sm
    self.iconSz = ZeD.T.cardIconSz

    -- Theme the rename entry every frame so theme/text-size changes apply instantly.
    if self._renameEntry then
        local T = ZeD.T
        if not self._renameEntry.fontColor then self._renameEntry.fontColor = {} end
        ZeD.colorSync(self._renameEntry.fontColor, T.text)
        self._renameEntry.font = T.fontF2
    end

    -- Compute head + body heights
    if self.item then
        self._headH = self:_calcHeadH()
        local bodyContentH = self:_calcBodyH()
        self._contentH = bodyContentH
        local fullH = self._headH + bodyContentH
        local newH = fullH
        if self.mode == "drawer" and self.parent then
            newH = math.min(newH, self.parent:getHeight())
        end
        if newH ~= self.height then self:setHeight(newH) end

        -- Scrollbar setup (body overflows below head)
        if self._sb then
            local T = ZeD.T
            local viewH = newH - self._headH
            local needsScroll = bodyContentH > viewH
            self._sb.visible = needsScroll
            if needsScroll then
                self._sb.width  = T.sp.scrollbarW
                self._sb.arrowH = T.sp.scrollbarW
                self._sb.x      = self:getWidth() - T.sp.scrollbarW
                self._sb.y      = self._headH
                self._sb.height = viewH
                self._sb:setBarSize(viewH / bodyContentH)
                local maxScroll = bodyContentH - viewH
                if self._scrollPixels > maxScroll then self._scrollPixels = maxScroll end
            else
                self._scrollPixels = 0
                self._sb:setScrollPos(0)
            end
        end
    end

    -- Position rename entry + action buttons within the sticky head.
    if self._renameEntry then
        local showRename = self._renaming
        if showRename then
            local T      = ZeD.T
            local nameX  = self.pad + self.iconSz + T.sp.sm
            local entryW = self:getWidth() - nameX - self.pad
            local entryY = self._nameY
            self._renameEntry:setX(nameX)
            self._renameEntry:setY(entryY)
            self._renameEntry:setWidth(entryW)
            self._renameEntry:setHeight(T.inputH)
            self._renameEntry:setVisible(true)

            -- Buttons below the text entry, right-aligned
            local btnY = entryY + T.inputH + T.sp.xs
            local bx = nameX + entryW
            local gap = T.sp.xs
            if self._renameCancelBtn then
                local bw = self._renameCancelBtn:getWidth()
                bx = bx - bw
                self._renameCancelBtn:setX(bx)
                self._renameCancelBtn:setY(btnY)
                self._renameCancelBtn:setVisible(true)
                bx = bx - gap
            end
            if self._renameResetBtn then
                local bw = self._renameResetBtn:getWidth()
                bx = bx - bw
                self._renameResetBtn:setX(bx)
                self._renameResetBtn:setY(btnY)
                self._renameResetBtn:setVisible(true)
                bx = bx - gap
            end
            if self._renameSaveBtn then
                local bw = self._renameSaveBtn:getWidth()
                bx = bx - bw
                self._renameSaveBtn:setX(bx)
                self._renameSaveBtn:setY(btnY)
                self._renameSaveBtn:setVisible(true)
            end
        else
            self._renameEntry:setVisible(false)
            if self._renameSaveBtn then self._renameSaveBtn:setVisible(false) end
            if self._renameResetBtn then self._renameResetBtn:setVisible(false) end
            if self._renameCancelBtn then self._renameCancelBtn:setVisible(false) end
        end
    end

    -- Card bg is transparent — the drawer surface provides the full-height background
    self.backgroundColor.a = 0
    -- Suppress ISPanel's 4-sided border — we draw 3 sides manually (no top)
    self.borderColor.a = 0
    ISPanel.prerender(self)

    -- 3-sided border: left, right, bottom — top suppressed per edge flag rule
    local bc = ZeD.T.border
    local w = self:getWidth()
    local h = self:getHeight()
    self:drawRect(0, 0, 1, h, bc.a or 1, bc.r, bc.g, bc.b)          -- left
    self:drawRect(w - 1, 0, 1, h, bc.a or 1, bc.r, bc.g, bc.b)      -- right
    self:drawRect(0, h - 1, w, 1, bc.a or 1, bc.r, bc.g, bc.b)      -- bottom

end

-- ---------------------------------------------------------------------------
-- RENDER HELPER: build M16 zone configs from getClothingZones() output
-- ---------------------------------------------------------------------------
local function buildZoneConfigs(item)
    local T    = ZeD.T
    local AS   = ZeD.ActionStrip
    local texPad = AS.getTex("housekeeping-057-pillow")
    local zones  = getClothingZones(item)
    local cfgs   = {}
    for _, zone in ipairs(zones) do
        local dock = nil
        if zone.condIconKey or zone.flagText then
            local dockFlag  = zone.flagText or "—"
            local dockColor = T[zone.flagColorKey] or T.textSec
            if zone.flagText == "Leather" then dockColor = T.matLeather
            elseif zone.flagText == "Denim" then dockColor = T.matDenim
            elseif zone.flagText == "Fabric" then dockColor = T.matFabric end
            local dockIcon  = zone.condIconKey and AS.getTex(zone.condIconKey) or texPad
            local dockState = (not zone.condIconKey) and "grey" or "active"
            dock = { flag = dockFlag, color = dockColor, icon = dockIcon, state = dockState }
        else
            dock = { flag = "OK", color = T.positive, icon = texPad, state = "grey" }
        end
        local soiledCfg = nil
        local hasAnySoil = (zone.bloodPct > 0) or (zone.hasDirt) or (zone.wetPct > 0.15)
        if hasAnySoil then
            soiledCfg = {
                blood = zone.bloodPct > 0   and math.floor(zone.bloodPct * 100) or nil,
                dirt  = zone.hasDirt        and true                            or nil,
                wet   = zone.wetPct  > 0.15 and math.floor(zone.wetPct  * 100) or nil,
            }
        end
        table.insert(cfgs, {
            name = zone.name, pct = math.floor(zone.zoneR * 100),
            bar = true, dock = dock, soiled = soiledCfg,
        })
    end
    return cfgs
end

-- ===========================================================================
-- RENDER: three-phase pipeline — sticky head → stenciled body → scrollbar
-- ===========================================================================
function ZeD_ItemCard:render()
    if not self.item then return end
    if self:getWidth() < 80 then return end
    local T=ZeD.T; local A=ZeD.Atoms; local M=ZeD.Molecules; local sp=T.sp; local item=self.item
    local w=self:getWidth(); local h=self:getHeight()
    local sbW = (self._sb and self._sb.visible) and self._sb.width or 0
    local pad=self.pad; local iconSz=self.iconSz
    local innerW=w-pad*2-sbW
    local colW=math.floor((innerW-self.colGap)/2)
    local compact = (colW < 70)
    local statRowH=getStatRowH()
    local bodyFH=getTextManager():getFontHeight(T.fontF2)
    local secH=getTextManager():getFontHeight(T.fontF1)
    local headFH=getTextManager():getFontHeight(T.fontF4)
    local btnSz=T.iconSm + 4
    local grooveH=2
    local tlg=sp.textLineGap
    local bvo=math.floor((statRowH - T.fillBarH) / 2)
    local leftX=pad; local rightX=pad+colW+self.colGap
    local cat = getItemCategory(item)

    -- Reset per-frame hit rect arrays
    self._foldHitRects  = {}
    self._zoneDockRects = {}

    -- =========================================================================
    -- PHASE 1: STICKY HEAD (before stencil — never scrolls)
    -- Background drawn in prerender() so children (rename entry) aren't obscured.
    -- =========================================================================
    local curY = pad

    -- Row 1: Icon + Name side-by-side
    local itex = safeGet(item,"getTexture")
    if itex then
        A.drawIcon(self, itex, leftX, curY, iconSz, 1, T.iconWhite)
    end
    local nameX   = leftX + iconSz + sp.sm
    local nameMaxW = innerW - iconSz - sp.sm
    local displayName = safeGet(item,"getDisplayName") or "???"
    local hasCustomName = safeGet(item,"isCustomName") or false

    -- Center name block on icon when shorter than icon
    local nameLines0 = wrapText(displayName, T.fontF4, nameMaxW)
    local nameBlockH = headFH * #nameLines0
    if hasCustomName then nameBlockH = nameBlockH + tlg + secH end
    local nameDrawY = curY + math.max(0, math.floor((iconSz - nameBlockH) / 2))
    self._nameY = nameDrawY

    if not self._renaming then
        local nameLines = nameLines0
        local nameH = headFH * #nameLines
        local nameColor = self._nameHover and T.accent or T.text
        local ny = nameDrawY
        for _, ln in ipairs(nameLines) do
            self:drawText(ln, nameX, ny, nameColor.r, nameColor.g, nameColor.b, nameColor.a, T.fontF4)
            ny = ny + headFH
        end
        if hasCustomName then
            local scriptItem = safeGet(item, "getScriptItem")
            local origName = scriptItem and safeGet(scriptItem, "getDisplayName") or ""
            self:drawText(origName, nameX, ny + tlg,
                T.textSec.r, T.textSec.g, T.textSec.b, T.textSec.a, T.fontF1)
        end
        -- Cache name hit rect for click-to-rename
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        self._nameHitRect = {x=ax+nameX, y=ay+nameDrawY, w=nameMaxW, h=nameH}
    else
        self._nameHitRect = nil
    end

    -- Advance past Row 1
    local nameH
    if self._renaming then
        nameH = T.inputH + sp.xs + T.buttonH + sp.xs
    else
        local nameLines = wrapText(displayName, T.fontF4, nameMaxW)
        nameH = headFH * #nameLines
        if hasCustomName then nameH = nameH + tlg + secH end
    end
    curY = curY + math.max(iconSz, nameH) + sp.cardAfterHead

    -- Row 2: Primary bar — label+value% on line 1, fill bar full-width on line 2
    local primaryBar = self:_getPrimaryBar(item)
    if primaryBar then
        M.drawStatRow(self, leftX, curY, innerW, primaryBar.label, math.floor(primaryBar.ratio*100).."%")
        curY = curY + statRowH + sp.cardAfterBody
        M.drawFillBar(self, leftX, curY, innerW, primaryBar.ratio)
        curY = curY + T.fillBarH + sp.cardAfterBody
    else
        curY = curY + sp.cardAfterBody
    end

    -- Row 3: Action strip
    local stripY = curY + sp.sm
    local DEFS = ZeD.ActionStrip.TOGGLE_DEFS
    self.toggleRects = M.drawActionStrip(self, leftX, stripY, DEFS, item, self.toggleHover)
    local verbs = getVerbsForItem(item)
    self._verbDefs = verbs
    self.verbRects = M.drawVerbStrip(self, w - pad, stripY, verbs, self.verbHover)
    self:_drawGpFocusOutline()
    curY = curY + sp.sm + btnSz + sp.sm

    -- Bottom border of sticky head
    A.drawDividerH(self, 0, curY, w, true)

    -- =========================================================================
    -- PHASE 2: SCROLLABLE BODY (inside stencil)
    -- =========================================================================
    local scrollOff = self._scrollPixels or 0
    self:setStencilRect(0, self._headH, w - sbW, h - self._headH)

    curY = self._headH + sp.cardAfterHead - scrollOff

    -- Badges
    local alerts = getStatusAlerts(item)
    if #alerts > 0 then
        local bx = leftX
        for _,al in ipairs(alerts) do bx = bx + A.drawBadge(self, al.text, bx, curY, al.variant) + sp.badgeGap end
        local badgeH = getTextManager():getFontHeight(T.fontF3) + sp.badgePadY * 2
        curY = curY + badgeH + 6
    end

    -- Stats
    local stats = getStatsForItem(item)
    if #stats > 0 then
        for _, st in ipairs(stats) do
            curY = curY + M.drawStatRow(self, leftX, curY, innerW, st.label, tostring(st.value), st.color)
        end
    end

    -- Category + Weight (labels)
    local wt = safeGet(item,"getActualWeight") or safeGet(item,"getWeight") or 0
    curY = curY + M.drawStatRow(self, leftX, curY, innerW, "Category", cat)
    curY = curY + M.drawStatRow(self, leftX, curY, innerW, "Weight", string.format("%.1f kg", wt))

    -- Divider
    curY = curY + sp.cardAfterBody
    A.drawDividerH(self, pad, curY, innerW)
    curY = curY + 1 + sp.cardAfterHead

    -- Secondary bars — two-line layout: label+% row, then fill bar full-width
    local allBars = getBarsForItem(item)
    if #allBars > 1 then
        for i = 2, #allBars do
            local bar = allBars[i]
            M.drawStatRow(self, leftX, curY, innerW, bar.label, math.floor(bar.ratio*100).."%")
            curY = curY + statRowH + sp.cardAfterBody
            M.drawFillBar(self, leftX, curY, innerW, bar.ratio)
            curY = curY + T.fillBarH
            if i < #allBars then curY = curY + sp.cardAfterLabel end
        end
        curY = curY + sp.cardAfterBody
    end

    -- ----- DISCLOSURES -----
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local bodyTop = ay + self._headH
    local bodyBot = ay + h

    if cat == "Clothing" then
        -- Per-Zone Detail disclosure
        local zones = buildZoneConfigs(item)
        local expanded = self._foldStates.clothing_zones
        local foldMx, foldMy = getMouseX(), getMouseY()
        local catHdrH = T.sp.colHdrH
        local hdrScreenY = ay + curY
        local hdrHovered = foldMx >= ax+leftX and foldMx < ax+leftX+innerW
                       and foldMy >= hdrScreenY and foldMy < hdrScreenY + catHdrH
                       and hdrScreenY >= bodyTop and hdrScreenY + catHdrH <= bodyBot
        curY = curY + M.drawSectionHeader(self, leftX, curY, innerW,
            "Per-Zone Detail", #zones, expanded, hdrHovered, T.fontF1, nil, leftX, catHdrH)
        table.insert(self._foldHitRects, {
            x=ax+leftX, y=ay+curY-catHdrH, w=innerW, h=catHdrH, key="clothing_zones"
        })

        if expanded and #zones > 0 then
            for i, zone in ipairs(zones) do
                if i > 1 then
                    A.drawGroove(self, leftX, curY, innerW)
                    curY = curY + grooveH
                end
                local zoneH = M.drawZoneRow(self, leftX, curY, innerW, zone, false)
                -- Store dock hit rect for each zone (structural dock button on right)
                if zone.dock and zone.dock.state ~= "grey" then
                    table.insert(self._zoneDockRects, {
                        x=ax+leftX, y=ay+curY, w=innerW, h=zoneH,
                        zoneIdx=i, zone=zone
                    })
                end
                curY = curY + zoneH
            end
        end

    elseif cat == "Food" then
        local nutrition   = getNutritionForItem(item)
        local ingredients = getIngredientsForItem(item)
        local foldMx, foldMy = getMouseX(), getMouseY()

        -- Nutrition Facts disclosure
        if #nutrition > 0 then
            local expanded = self._foldStates.food_nutrition
            local catHdrH = T.sp.colHdrH
            local hdrScreenY = ay + curY
            local hdrHovered = foldMx >= ax+leftX and foldMx < ax+leftX+innerW
                           and foldMy >= hdrScreenY and foldMy < hdrScreenY + catHdrH
                           and hdrScreenY >= bodyTop and hdrScreenY + catHdrH <= bodyBot
            curY = curY + M.drawSectionHeader(self, leftX, curY, innerW,
                "Nutrition Facts", nil, expanded, hdrHovered, T.fontF1, nil, leftX, catHdrH)
            table.insert(self._foldHitRects, {
                x=ax+leftX, y=ay+curY-catHdrH, w=innerW, h=catHdrH, key="food_nutrition"
            })

            if expanded then
                local thickRule = 2; local thinRule = 1
                curY = curY + sp.cardBeforeHead
                -- Nutrition Facts heading: F4 norm (content voice, not chrome)
                local nfFont = T.fontF4
                local nfC = T.toneNorm
                self:drawText("Nutrition Facts", leftX, curY, nfC.r, nfC.g, nfC.b, nfC.a or 1, nfFont)
                curY = curY + getTextManager():getFontHeight(nfFont) + sp.cardAfterHead
                local bc2 = T.borderS
                self:drawRect(leftX, curY, innerW, thickRule, bc2.a or 1, bc2.r, bc2.g, bc2.b)
                curY = curY + thickRule + sp.cardAfterHead
                local rc = T.border
                for i, nut in ipairs(nutrition) do
                    curY = curY + M.drawStatRow(self, leftX, curY, innerW, nut.label, nut.value)
                    if i < #nutrition and not nutrition[i+1].sub then
                        self:drawRect(leftX, curY, innerW, thinRule, rc.a or 1, rc.r, rc.g, rc.b)
                        curY = curY + thinRule + sp.cardAfterBody
                    end
                end
                curY = curY + sp.cardAfterBody
            end
        end

        -- Ingredients disclosure
        if #ingredients > 0 then
            local expanded = self._foldStates.food_ingredients
            local catHdrH = T.sp.colHdrH
            local hdrScreenY = ay + curY
            local hdrHovered = foldMx >= ax+leftX and foldMx < ax+leftX+innerW
                           and foldMy >= hdrScreenY and foldMy < hdrScreenY + catHdrH
                           and hdrScreenY >= bodyTop and hdrScreenY + catHdrH <= bodyBot
            curY = curY + M.drawSectionHeader(self, leftX, curY, innerW,
                "Ingredients", #ingredients, expanded, hdrHovered, T.fontF1, true, leftX, catHdrH)
            table.insert(self._foldHitRects, {
                x=ax+leftX, y=ay+curY-catHdrH, w=innerW, h=catHdrH, key="food_ingredients"
            })

            if expanded then
                curY = curY + sp.cardAfterHead
                local font = T.fontF1
                local labelStr = "INGREDIENTS: "
                local names = {}
                for _, ing in ipairs(ingredients) do names[#names + 1] = ing.name end
                local namesStr = table.concat(names, ", ")
                local labelW = getTextManager():MeasureStringX(font, labelStr)
                self:drawText(labelStr, leftX, curY, T.textSec.r, T.textSec.g, T.textSec.b, T.textSec.a, font)
                local wrapX = leftX + labelW
                local maxW = innerW
                local remaining = namesStr
                local lineH = secH + 2
                while remaining and #remaining > 0 do
                    local availW = maxW - (wrapX - leftX)
                    local fits = #remaining
                    while fits > 0 and getTextManager():MeasureStringX(font, remaining:sub(1, fits)) > availW do
                        local breakAt = fits
                        while breakAt > 0 and remaining:sub(breakAt, breakAt) ~= "," and remaining:sub(breakAt, breakAt) ~= " " do
                            breakAt = breakAt - 1
                        end
                        if breakAt > 0 then fits = breakAt else fits = fits - 1 end
                    end
                    if fits <= 0 then fits = 1 end
                    local chunk = remaining:sub(1, fits)
                    local tc = T.text
                    self:drawText(chunk, wrapX, curY, tc.r, tc.g, tc.b, tc.a, font)
                    remaining = remaining:sub(fits + 1)
                    remaining = remaining:match("^[%s,]*(.*)")
                    if remaining and #remaining > 0 then
                        curY = curY + lineH
                        wrapX = leftX
                    end
                end
                curY = curY + lineH

                curY = curY + sp.cardAfterLabel
                local ct = safeGet(item, "getMinutesToCook")
                curY = curY + M.drawStatRow(self, leftX, curY, innerW, "Cook time", (ct and ct>0) and (math.floor(ct).." min") or "-")
            end
        end
    end
    -- (Weapon/other: no disclosures — lean card)

    self:clearStencilRect()

    -- =========================================================================
    -- PHASE 3: SCROLLBAR (after stencil)
    -- =========================================================================
    if self._sb and self._sb.visible then
        self._sb:draw(self)
    end
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
    if not self.item then return 100 end
    if self:getWidth() < 80 then return 100 end
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
                    local cur = ZeD.ActionStrip.getState(item, tkey)
                    ZeD.ActionStrip.setState(item, tkey, not cur)
                end,
            }
        end
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

-- Called by card:render() after action strips draw. Outlines the gp-focused
-- button with an accent border so the user sees which button will fire on A.
-- Looks up the button by id in toggleRects / verbRects (absolute coords → local).
function ZeD_ItemCard:_drawGpFocusOutline()
    local id = self._gpFocusedBtnId
    if not id then return end
    -- Only paint when the window says our card zone is currently focused.
    -- Without this guard, the outline would persist after focus bumpers away.
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local w     = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow()
    local zone  = (w and Focus.getFocusedZone) and Focus.getFocusedZone(w) or nil
    if not zone or zone.zone ~= "charItemCard" then return end

    local r = nil
    local DEFS = ZeD.ActionStrip.TOGGLE_DEFS
    for i, def in ipairs(DEFS) do
        if id == "toggle_" .. def.key then
            r = self.toggleRects and self.toggleRects[i]; break
        end
    end
    if not r then
        for i, vdef in ipairs(self._verbDefs or {}) do
            if id == "verb_" .. vdef.key then
                r = self.verbRects and self.verbRects[i]; break
            end
        end
    end
    if not r then return end

    local T  = ZeD.T
    local ax = self:getAbsoluteX()
    local ay = self:getAbsoluteY()
    local lx = r.x - ax
    local ly = r.y - ay
    local c  = T.accent
    -- 2px outline inset 1px outside the button
    local ox, oy = lx - 1, ly - 1
    local ow, oh = r.w + 2, r.h + 2
    self:drawRectBorder(ox, oy, ow, oh, c.a or 1, c.r, c.g, c.b)
    self:drawRectBorder(ox - 1, oy - 1, ow + 2, oh + 2, (c.a or 1) * 0.5, c.r, c.g, c.b)
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
