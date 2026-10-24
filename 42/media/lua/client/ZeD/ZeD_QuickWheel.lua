-- ZeD-UI/42/media/lua/client/ZeD/ZeD_QuickWheel.lua
-- ============================================================================
-- QUICK USE ON THE CONTROLLER'S D-PAD RIGHT WHEEL (HOOK_MAP row 29)
-- Director, Oct 15 2026: "Add more functions to the radial menus for
-- controller. Like eating, drinking, smoking ... add what is missing or is
-- logical to double the place an action can be triggered, for QOL. What
-- actions should be quick radial actions that require selecting a list of
-- items or interaction with multiple things."
--
-- Vanilla's D-pad Right wheel (the map, the mini-map, zones, the survival
-- guide) gains the everyday "pick one of the things I carry" actions, each
-- only when there is something to pick:
--   Eat          food that feeds you (spoiling soonest first; rotten last)
--   Drink        water and drinks (vanilla's thirst-sized sip from water)
--   Smoke        cigarettes and the like (when there is a flame to light them)
--   Take pills   pill bottles
--   Read         books, magazines, comics (not when it is too dark)
--   Treat wounds the Health tab, when a wound wants seeing to
-- Picking one fills the same wheel with those items (one slice per kind, the
-- best of it, "x3" when there are more) and a Back slice, the way vanilla's
-- emote wheel opens its groups. Every pick runs vanilla's own context-menu
-- verb (ISInventoryPaneContextMenu: eat / drink / take pill / read), with its
-- rules: items come out of bags first, masks come off, lighters are found.
-- Since Oct 23 2026 these lists feed the Character wheel on D-pad Left
-- (ZeD_DpadWheels.lua, DPAD_WHEELS_SPEC.md); this file no longer adds to the
-- game's D-pad Right wheel, which is the World wheel now.
-- ============================================================================

require "ISUI/ISDPadWheels"
require "ISUI/ISInventoryPaneContextMenu"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.QuickWheel = ZeD.QuickWheel or {}
local Q = ZeD.QuickWheel

local MAX_ITEMS = 8
local BACK_TEX = "media/ui/emotes/back.png"

local function _safe(fn, default) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return default end

-- everything the character carries: the main inventory and the bags in it / worn
local function carried(playerObj)
    local out = {}
    local function scan(container, depth)
        local items = container and _safe(function() return container:getItems() end, nil)
        if not items then return end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            out[#out + 1] = it
            if depth < 2 and instanceof(it, "InventoryContainer") then scan(_safe(function() return it:getInventory() end, nil), depth + 1) end
        end
    end
    scan(playerObj:getInventory(), 0)
    return out
end

-- ---------------------------------------------------------------------------
-- what counts (vanilla's own tests, ISInventoryPaneContextMenu.createMenu)
-- ---------------------------------------------------------------------------
local DRINK = nil
local function drinkWord() DRINK = DRINK or getText("ContextMenu_Drink"); return DRINK end

local function isSmokable(it) return _safe(function() return it:hasTag(ItemTag.SMOKABLE) end, false) end

local function isFood(it)
    if _safe(function() return it:getCategory() end, "") ~= "Food" then return false end
    if isSmokable(it) then return false end
    if _safe(function() return it:getScriptItem():isCantEat() and not it:getScriptItem():getOpeningRecipe() end, false) then return false end
    local opt = _safe(function() return it:getCustomMenuOption() end, nil)
    if opt and opt ~= getText("ContextMenu_Eat") then return false end   -- (a drink in a carton says Drink)
    return _safe(function() return it:getHungChange() < 0 end, false) or _safe(function() return it:getOpeningRecipe() ~= nil end, false)
end

local function isFoodDrink(it)
    return _safe(function() return it:getCategory() end, "") == "Food" and not isSmokable(it)
        and _safe(function() return it:getCustomMenuOption() end, nil) == drinkWord()
end

local function isWater(it) return _safe(function() return it:isWaterSource() and it:getFluidContainer():getAmount() > 0 end, false) end

local function isBeverage(it)
    if isWater(it) then return false end
    return _safe(function()
        local fc = it:getFluidContainer()
        if not fc or fc:isEmpty() or fc:isMultiTileMoveable() then return false end
        local fl = fc:getPrimaryFluid()
        return fl ~= nil and fl:isCategory(FluidCategory.Beverage)
    end, false)
end

local function isPills(it)
    return _safe(function() return it:hasTag(ItemTag.CONSUMABLE) end, false) and instanceof(it, "DrainableComboItem")
end

local function isReadable(it)
    if _safe(function() return it:getCategory() end, "") ~= "Literature" then return false end
    if _safe(function() return it:canBeWrite() end, false) then return false end
    if _safe(function() return it:getModData().printMedia end, nil) then return false end
    return true
end

-- a flame for a smoke (vanilla's test in doEatOption)
local function notEmpty(item) return not instanceof(item, "DrainableComboItem") or item:getCurrentUsesFloat() > 0 end   -- (vanilla's predicateNotEmpty is local to its file)
local function canLight(playerObj, it)
    if _safe(function() return playerObj:getVehicle() and playerObj:getVehicle():canLightSmoke(playerObj) end, false) then return true end
    if _safe(function() return ISInventoryPaneContextMenu.hasOpenFlame(playerObj) end, false) then return true end
    local list = _safe(function() return it:getRequireInHandOrInventory() end, nil)
    if not list then return true end
    for i = 0, list:size() - 1 do
        local ft = moduleDotType(it:getModule(), list:get(i))
        if _safe(function() return playerObj:getInventory():getFirstTypeEvalRecurse(ft, notEmpty) end, nil) then return true end
    end
    return false
end

-- one entry per kind of item: the best instance and how many there are
local function byKind(list, better)
    local kinds, order = {}, {}
    for _, it in ipairs(list) do
        local ft = _safe(function() return it:getFullType() end, tostring(it))
        local k = kinds[ft]
        if not k then k = { item = it, n = 0 }; kinds[ft] = k; order[#order + 1] = k end
        k.n = k.n + 1
        if better and better(it, k.item) then k.item = it end
    end
    return order
end

-- food: fresh before rotten, then whatever spoils soonest
local function spoilRank(it)
    if _safe(function() return it:isRotten() end, false) then return 1e9 end
    local off = _safe(function() return it:getOffAge() end, 1e8)
    local age = _safe(function() return it:getAge() end, 0)
    if off >= 1e6 then return 1e8 end
    return off - age
end

-- ---------------------------------------------------------------------------
-- the actions (vanilla's verbs)
-- ---------------------------------------------------------------------------
local function eat(playerObj, it)
    local pn = playerObj:getPlayerNum()
    local opening = nil
    local name = _safe(function() return it:getOpeningRecipe() end, nil)
    if name then
        opening = _safe(function() return getScriptManager():getCraftRecipe(name) end, nil)
        if opening then
            local ok = _safe(function()
                local logic = HandcraftLogic.new(playerObj, nil, nil)
                logic:setContainers(ISInventoryPaneContextMenu.getContainers(playerObj))
                logic:setRecipeFromContextClick(opening, it)
                return logic:canPerformCurrentRecipe()
            end, false)
            if not ok then opening = nil end
        end
    end
    ISInventoryPaneContextMenu.onEatItems({ it }, 1, pn, opening, opening and 100 or nil)
end

local function drink(playerObj, it)
    if isWater(it) then
        local thirst = _safe(function() return playerObj:getStats():get(CharacterStat.THIRST) end, 0.5)
        local amount = _safe(function() return it:getFluidContainer():getAmount() end, 1)
        local units = math.min(thirst * 2, amount)
        local percent = amount > 0 and math.max(0.05, units / amount) or 1
        ISInventoryPaneContextMenu.onDrinkForThirst(it, playerObj, percent)
    elseif isBeverage(it) then
        ISInventoryPaneContextMenu.onDrinkFluid(it, 1, playerObj)
    else
        ISInventoryPaneContextMenu.onEatItems({ it }, 1, playerObj:getPlayerNum())
    end
end

local function smoke(playerObj, it) ISInventoryPaneContextMenu.onEatItems({ it }, 1, playerObj:getPlayerNum()) end
local function pills(playerObj, it) ISInventoryPaneContextMenu.takePill(it, playerObj:getPlayerNum()) end
local function read(playerObj, it) ISInventoryPaneContextMenu.readItem(it, playerObj:getPlayerNum()) end

-- a wound that wants seeing to (bleeding, or an injury with no bandage on it)
local function hurt(playerObj)
    local bd = _safe(function() return playerObj:getBodyDamage() end, nil)
    local parts = bd and _safe(function() return bd:getBodyParts() end, nil)
    if not parts then return false end
    local KINDS = { "bleeding", "scratched", "deepWounded", "isCut", "bitten", "haveBullet", "haveGlass" }
    for i = 0, parts:size() - 1 do
        local p = parts:get(i)
        local wound = false
        for _, m in ipairs(KINDS) do   -- each asked on its own: one the build lacks must not hide the rest
            if _safe(function() return p[m](p) end, false) then wound = true; break end
        end
        if wound and not _safe(function() return p:bandaged() end, false) then return true end
    end
    return false
end

-- the Health tab in the Character window (the pair opens for the controller)
local function treat(playerObj)
    local pn = playerObj:getPlayerNum()
    if not (ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad) then return end
    pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, pn)
    local tries = 0
    local function tick()
        tries = tries + 1
        local win = ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
        local strip = win and win._tabStripPanel
        local done = false
        if win and win._activeTab == "health" and win._drawerOpen then done = true
        elseif strip and strip._hitZones then
            for _, z in ipairs(strip._hitZones) do
                if z.id == "tab:health" then strip:onMouseDown(z.x + 2, z.y + 2); done = true; break end
            end
        end
        if done or tries >= 30 then Events.OnTick.Remove(tick) end
    end
    Events.OnTick.Add(tick)
end

-- ---------------------------------------------------------------------------
-- the groups
-- ---------------------------------------------------------------------------
local GROUPS = {
    { id = "eat", label = "ContextMenu_Eat", test = isFood, act = eat,
      better = function(a, b) return spoilRank(a) < spoilRank(b) end, order = function(x, y) return spoilRank(x.item) < spoilRank(y.item) end,
      off = function(p) return _safe(function() return p:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 end, false) end },
    { id = "drink", label = "ContextMenu_Drink", test = function(it) return isWater(it) or isBeverage(it) or isFoodDrink(it) end, act = drink,
      order = function(x, y) return (isWater(x.item) and 0 or 1) < (isWater(y.item) and 0 or 1) end },
    { id = "smoke", label = "ContextMenu_Smoke", test = isSmokable, act = smoke, usable = canLight },
    { id = "pills", label = "ContextMenu_Take_pills", test = isPills, act = pills },
    { id = "read", label = "ContextMenu_Read", test = isReadable, act = read,
      off = function(p) return _safe(function() return p:tooDarkToRead() end, false) end },
}

function Q.collect(playerObj, g)
    if g.off and g.off(playerObj) then return {} end
    local list = {}
    for _, it in ipairs(carried(playerObj)) do
        if g.test(it) and (not g.usable or g.usable(playerObj, it)) then list[#list + 1] = it end
    end
    local kinds = byKind(list, g.better)
    if g.order then table.sort(kinds, g.order) end
    return kinds
end

local function centre(menu, pn)
    menu:setX(getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn) / 2 - menu:getWidth() / 2)
    menu:setY(getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) / 2 - menu:getHeight() / 2)
end

-- a group's items on the wheel (vanilla's emote-group pattern: refill, show again)
function Q.openGroup(playerObj, gid)
    local pn = playerObj:getPlayerNum()
    local g
    for _, x in ipairs(GROUPS) do if x.id == gid then g = x end end
    if not g then return end
    local menu = getPlayerRadialMenu(pn)
    menu:clear()
    for i, k in ipairs(Q.collect(playerObj, g)) do
        if i > MAX_ITEMS then break end
        local name = _safe(function() return k.item:getDisplayName() end, "?")
        if k.n > 1 then name = name .. "  x" .. k.n end
        menu:addSlice(name, _safe(function() return k.item:getTex() end, nil), g.act, playerObj, k.item)
    end
    local jd = JoypadState.players[pn + 1]
    menu:addSlice(getText("IGUI_Emote_Back"), getTexture(BACK_TEX), ISDPadWheels.onDisplayRight, { player = pn, id = jd and jd.id or nil })
    centre(menu, pn)
    menu:addToUIManager()
    if JoypadState.players[pn + 1] then
        menu:setHideWhenButtonReleased(Joypad.DPadRight)
        setJoypadFocus(pn, menu)
        playerObj:setJoypadIgnoreAimUntilCentered(true)
    end
end

-- the groups that have something in them, added to vanilla's D-pad Right wheel
function Q.addGroups(menu, playerObj)
    for _, g in ipairs(GROUPS) do
        local kinds = Q.collect(playerObj, g)
        if #kinds > 0 then
            menu:addSlice(ZeD.tr(g.label), _safe(function() return kinds[1].item:getTex() end, nil), Q.openGroup, playerObj, g.id)
            local s = menu.slices and menu.slices[#menu.slices]
            if s then s._zedSub = true end   -- (the wheel marks it as opening more)
        end
    end
    if hurt(playerObj) then
        menu:addSlice(ZeD.tr("UI_ZeD_Wheel_TreatWounds"), getTexture("media/ui/Heart2_On.png"), treat, playerObj)
    end
end

-- a group by id ("eat", "drink", "smoke", "pills", "read") and the
-- wound test, for the D-pad wheels (ZeD_DpadWheels.lua). Oct 23 2026: the
-- Character wheel (D-pad Left) takes these lists over; this file no longer
-- adds to the game's D-pad Right wheel (DPAD_WHEELS_SPEC section 4).
function Q.group(id)
    for _, g in ipairs(GROUPS) do if g.id == id then return g end end
    return nil
end
Q.hurt = hurt
Q.isWater = isWater
