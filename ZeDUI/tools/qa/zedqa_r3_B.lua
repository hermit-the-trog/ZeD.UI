-- ZeDUI/tools/qa/zedqa_r3_B.lua  (Oct 26 2026, compatibility round 3, group B)
-- In game on a copy of ZeD-QA with group B's mods on (zedqa_mods_run.ps1 -ModList ... -Manifest compat_r3_B.txt).
-- A survey of ZeD's windows with the group's mods loaded, then the group's own mod features:
--   census of the visible UI (anything that is not ZeD's: a vanilla window over ZeD's, a mod's HUD),
--   the item menu on an apple, a shirt, a book, a bag (rows printed: which mods add rows),
--   the world menu on the character's square, the item tooltip of a shirt and a book,
--   ZeD's Character tabs (equip, health, skills, identity) and World tabs (craft, build, maps),
--   then the group's own steps (mod windows opened through the mods' own functions).
-- Each capture waits until both windows are still (30 still ticks, cap 900). Screenshots zqa_r3B_*.png.
-- Everything it adds is taken back. grep "ZEDQA r3B".
local TAG = "r3B"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local added = {}
local function give(ft) local ok, it = pcall(function() return p:getInventory():AddItem(ft) end); if ok and it then added[#added + 1] = it; return it end; say("note: no item " .. ft); return nil end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_" .. name .. ".png") end); say("shot zqa_" .. TAG .. "_" .. name .. ".png") end
local function tabsOf(strip) local out = {}; for _, z in ipairs(strip and strip._hitZones or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[z.id:sub(5)] = z end end; return out end
local function clickChar(id) local w = CW.getWindow(); local z = w and tabsOf(w._tabStripPanel)[id]; if z then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2); return true end; say("note: no char tab " .. id); return false end
local function clickWorld(id) local w = WW.getWindow(); local z = w and tabsOf(w._actionTabStrip)[id]; if z then w._actionTabStrip:onMouseDown(z.x + 2, z.y + 2); return true end; say("note: no world tab " .. id); return false end
local function census(label)
    local ui = UIManager.getUI()
    local parts = {}
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e:isVisible() then
            local t = e:getTable()
            local ty = tostring(t and (t.Type or t.type) or e:getClass():getSimpleName())
            parts[#parts + 1] = string.format("%s@%d,%d,%dx%d", ty, math.floor(e:getX()), math.floor(e:getY()), math.floor(e:getWidth()), math.floor(e:getHeight()))
        end
    end
    say("ui " .. label .. ": " .. table.concat(parts, " ; "))
    -- vanilla windows ZeD replaces, shown anyway
    local inv = getPlayerInventory(0); local loot = getPlayerLoot(0)
    say("vanilla " .. label .. ": inventory page shown " .. tostring(inv and inv:getIsVisible()) .. ", loot page shown " .. tostring(loot and loot:getIsVisible())
        .. ", info panel shown " .. tostring(getPlayerInfoPanel(0) and getPlayerInfoPanel(0):getIsVisible()))
end
local function menuRows()
    local v = getPlayerContextMenu(0)
    local m = v and v._zedMenu
    local lv = m and m._levels and m._levels[1]
    local names = {}
    if lv then for _, r in ipairs(lv.rows or {}) do names[#names + 1] = r.sep and "|" or tostring(r.def and r.def.name) end
    elseif v then for _, o in ipairs(v.options or {}) do names[#names + 1] = tostring(o.name) end end
    return table.concat(names, ", "), m
end
local function closeMenu() local v = getPlayerContextMenu(0); if v and v._zedMenu then pcall(function() v._zedMenu:close() end) end end
local ctxOpt = ZeD.Settings and ZeD.Settings.contextStyleOption
local ctxWas = ctxOpt and ctxOpt:getValue()
local tip
local function showTip(item, x, y)
    if tip then pcall(function() tip:removeFromUIManager() end); tip = nil end
    if not item then return end
    tip = ISToolTipInv:new(item)
    tip:initialise(); tip:addToUIManager(); tip:setVisible(true)
    tip:setOwner(nil); tip:setCharacter(p)
    tip.followMouse = false; tip:setX(x); tip:setY(y)
    tip.anchorBottomLeft = nil
end
local function hideTip() if tip then pcall(function() tip:removeFromUIManager() end); tip = nil end end

-- the windows still (place, size, drawer width) for 30 checks in a row
local function shape()
    local t = {}
    for _, w in ipairs({ CW.getWindow(), WW.getWindow() }) do
        if w and w:isVisible() then t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)) end
    end
    return table.concat(t, ";")
end
local Q = {}
-- step(name, fn, shotName): run fn, wait until still, capture shotName if given
local function step(name, fn, shotName, extraWait) Q[#Q + 1] = { name = name, fn = fn, shot = shotName, extra = extraWait or 0 } end

local apple, shirt, book, bag, vhs
step("setup", function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    p:setGodMod(true)
    if not CW.isOpen() then CW.toggleBothPaired(0) end
    apple = give("Base.Apple"); shirt = give("Base.Shirt_FormalWhite"); book = give("Base.BookCarpentry1"); bag = give("Base.Bag_Schoolbag"); vhs = give("Base.VHS_Retail")
    clickChar("loot"); clickWorld("loot")
end, "1_loot", 20)
step("census", function() census("loot") end)
local function itemMenu(label, it, shotName)
    step("menu " .. label, function() if it then ISInventoryPaneContextMenu.createMenu(0, true, { it }, 900, 500) end end, nil, 10)
    step("menu rows " .. label, function() local rows = menuRows(); say("menu " .. label .. ": " .. rows) end, shotName)
    step("menu close " .. label, function() closeMenu() end)
end
step("menus", function() if ctxOpt then ctxOpt:setValue(2) end end)
itemMenu("apple", apple, "2_menu_apple")
itemMenu("shirt", shirt, nil)
itemMenu("book", book, nil)
itemMenu("bag", bag, nil)
step("world menu", function()
    local sq = p:getCurrentSquare()
    local objs = {}
    if sq then for i = 0, sq:getObjects():size() - 1 do objs[#objs + 1] = sq:getObjects():get(i) end end
    ISWorldObjectContextMenu.createMenu(0, objs, 900, 500, false)
end, nil, 10)
step("world menu rows", function() say("world menu: " .. menuRows()) end, "3_menu_world")
step("world menu close", function() closeMenu(); if ctxOpt and ctxWas then ctxOpt:setValue(ctxWas) end end)
-- the item tooltip with ZeD (its own ISToolTipInv.render) and in ZeD's safe mode (the game's render, with any
-- mod's wrapper round it): a mod line that shows only in safe mode is lost under ZeD's tooltip
local seed
local safeOpt = ZeD.Settings and ZeD.Settings.safeModeOption
local safeWas = safeOpt and safeOpt:getValue()
local function safe(on) if safeOpt then safeOpt:setValue(on and 2 or 1); pcall(function() ZeD.Safe.reread() end) end end
step("seed", function() seed = give("Base.CarrotBagSeed2") end)
for _, pair in ipairs({ { "shirt", function() return shirt end }, { "book", function() return book end }, { "vhs", function() return vhs end }, { "seed", function() return seed end } }) do
    step("tip " .. pair[1], function() showTip(pair[2](), 900, 300) end, "4_tip_" .. pair[1] .. "_zed", 10)
    step("tip " .. pair[1] .. " size", function() say("tip " .. pair[1] .. " zed " .. (tip and (math.floor(tip:getWidth()) .. "x" .. math.floor(tip:getHeight())) or "none")); hideTip(); safe(true) end, nil, 10)
    step("tip " .. pair[1] .. " safe", function() showTip(pair[2](), 900, 300) end, "5_tip_" .. pair[1] .. "_safe", 10)
    step("tip " .. pair[1] .. " safe size", function() say("tip " .. pair[1] .. " safe " .. (tip and (math.floor(tip:getWidth()) .. "x" .. math.floor(tip:getHeight())) or "none")); hideTip(); safe(false); if safeOpt and safeWas then safeOpt:setValue(safeWas); pcall(function() ZeD.Safe.reread() end) end end, nil, 20)
end
step("windows back", function() if not CW.isOpen() then CW.toggleBothPaired(0) end; census("after safe mode") end, nil, 30)
for _, t in ipairs({ "equip", "health", "skills", "identity" }) do
    step("char " .. t, function() clickChar(t) end, "6_char_" .. t, 10)
end
step("char loot", function() clickChar("loot") end)
for _, t in ipairs({ "craft", "build", "maps" }) do
    step("world " .. t, function() clickWorld(t) end, "7_world_" .. t, 10)
end
step("world loot", function() clickWorld("loot"); census("tabs walked") end)
-- group B: moodles on (hungry, thirsty, tired, bored, stressed), a scratch, some XP; the HUD with the
-- windows shut and open, the Health tab with the wound; stats and wound put back
local st = p:getStats()
local keptStats = {}
local WANT = { HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75, BOREDOM = 0.6, STRESS = 0.6 }
local part
step("moodles on", function()
    for k, v in pairs(WANT) do pcall(function() keptStats[k] = st:get(CharacterStat[k]); st:set(CharacterStat[k], v) end) end
    pcall(function() part = p:getBodyDamage():getBodyPart(BodyPartType.Hand_L); part:setScratched(true, true) end)
    pcall(function() p:getXp():AddXP(Perks.Carpentry, 40); p:getXp():AddXP(Perks.Fitness, 15) end)
end, nil, 60)
step("hud windows open", function() census("moodles, windows open") end, "8_hud_open", 30)
step("windows shut", function() if CW.isOpen() then CW.toggleBothPaired(0) end end, "9_hud_shut", 60)
step("hud census shut", function() census("windows shut") end)
step("windows open", function() if not CW.isOpen() then CW.toggleBothPaired(0) end end, nil, 30)
step("health with wound", function() clickChar("health") end, "10_health_wound", 20)
step("skills after xp", function() clickChar("skills") end, "11_skills_xp", 10)
step("vanilla health panel", function() census("health") ; clickChar("loot") end)
step("stats back", function()
    for k, v in pairs(keptStats) do pcall(function() st:set(CharacterStat[k], v) end) end
    pcall(function() part:setScratched(false, true); part:RestoreToFullHealth() end)
end)

step("put back", function()
    hideTip(); closeMenu()
    for _, it in ipairs(added) do pcall(function() if it:getContainer() then it:getContainer():DoRemoveItem(it) end end) end
    clickChar("loot"); clickWorld("loot")
    census("end")
end)

local qi, phase, stillLast, stillN, waited = 1, "run", nil, 0, 0
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); say("DONE"); return end
    if phase == "run" then
        local ok, e = pcall(s.fn)
        if not ok then say("ERR step " .. s.name .. ": " .. tostring(e)) end
        phase, stillLast, stillN, waited = "wait", nil, 0, 0
        return
    end
    waited = waited + 1
    local sh = shape()
    if sh == stillLast then stillN = stillN + 1 else stillLast, stillN = sh, 0 end
    if (stillN >= 30 and waited >= 10 + s.extra) or waited >= 900 then
        if waited >= 900 then say("WARN windows never still at " .. s.name) end
        if s.shot then shot(s.shot) end
        qi = qi + 1; phase = "run"
    end
end
Events.OnTick.Add(onTick)
say("start")
