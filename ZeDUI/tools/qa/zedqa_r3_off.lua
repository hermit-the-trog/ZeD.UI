-- ZeDUI/tools/qa/zedqa_r3_off.lua  (Oct 26 2026, compatibility round 3)
-- In game WITHOUT ZeD-UI (zedqa_off_run.ps1 -Tag r3off): the same group's mods, the game's own UI, for the
-- comparison with zedqa_r3_<G>.lua: a census of the visible UI, moodles on (hungry, thirsty, tired, bored,
-- stressed) with a scratch and some XP, the HUD, the game's inventory and loot windows, the game's character
-- window on Health and Skills, the item tooltip of a seed packet and a shirt. Stats, wound and items put back.
-- Screenshots zqa_r3off_*.png. grep "ZEDQA r3off".
local TAG = "r3off"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_" .. name .. ".png") end); say("shot zqa_" .. TAG .. "_" .. name .. ".png") end
local function census(label)
    local ui = UIManager.getUI(); local parts = {}
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:isVisible() then local t = e:getTable()
        parts[#parts + 1] = string.format("%s@%d,%d,%dx%d", tostring(t and (t.Type or t.type) or e:getClass():getSimpleName()), math.floor(e:getX()), math.floor(e:getY()), math.floor(e:getWidth()), math.floor(e:getHeight())) end end
    say("ui " .. label .. ": " .. table.concat(parts, " ; "))
end
local added = {}
local function give(ft) local ok, it = pcall(function() return p:getInventory():AddItem(ft) end); if ok and it then added[#added + 1] = it; return it end; return nil end
local st = p:getStats()
local kept = {}
local part, tip, seed, shirt
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    p:setGodMod(true)
    for k, v in pairs({ HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75, BOREDOM = 0.6, STRESS = 0.6 }) do pcall(function() kept[k] = st:get(CharacterStat[k]); st:set(CharacterStat[k], v) end) end
    pcall(function() part = p:getBodyDamage():getBodyPart(BodyPartType.Hand_L); part:setScratched(true, true) end)
    pcall(function() p:getXp():AddXP(Perks.Carpentry, 40) end)
    seed = give("Base.CarrotBagSeed2"); shirt = give("Base.Shirt_FormalWhite")
end)
step(150, function() census("hud"); shot("1_hud") end)
step(30, function() pcall(function() getPlayerInventory(0):setVisible(true); getPlayerLoot(0):setVisible(true) end) end)
step(60, function() census("inventory"); shot("2_inventory") end)
step(10, function()
    tip = ISToolTipInv:new(seed); tip:initialise(); tip:addToUIManager(); tip:setVisible(true); tip:setOwner(nil); tip:setCharacter(p)
    tip.followMouse = false; tip:setX(900); tip:setY(300)
end)
step(40, function() say("tip seed " .. math.floor(tip:getWidth()) .. "x" .. math.floor(tip:getHeight())); shot("3_tip_seed"); tip:removeFromUIManager() end)
step(10, function()
    tip = ISToolTipInv:new(shirt); tip:initialise(); tip:addToUIManager(); tip:setVisible(true); tip:setOwner(nil); tip:setCharacter(p)
    tip.followMouse = false; tip:setX(900); tip:setY(300)
end)
step(40, function() say("tip shirt " .. math.floor(tip:getWidth()) .. "x" .. math.floor(tip:getHeight())); shot("4_tip_shirt"); tip:removeFromUIManager() end)
step(10, function() pcall(function() getPlayerInfoPanel(0):toggleView(getText("IGUI_XP_Health")) end) end)
step(60, function() census("health"); shot("5_health") end)
step(10, function() pcall(function() getPlayerInfoPanel(0):toggleView(getText("IGUI_XP_Skills")) end) end)
step(60, function() shot("6_skills") end)
step(10, function()
    pcall(function() getPlayerInfoPanel(0):setVisible(false) end)
    for k, v in pairs(kept) do pcall(function() st:set(CharacterStat[k], v) end) end
    pcall(function() part:setScratched(false, true); part:RestoreToFullHealth() end)
    for _, it in ipairs(added) do pcall(function() if it:getContainer() then it:getContainer():DoRemoveItem(it) end end) end
    say("DONE")
end)
local qi, n = 1, 0
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    n = n + 1
    if n < s.n then return end
    n = 0; qi = qi + 1
    local ok, e = pcall(s.fn); if not ok then say("ERR " .. tostring(e)) end
end
Events.OnTick.Add(onTick)
say("start")
