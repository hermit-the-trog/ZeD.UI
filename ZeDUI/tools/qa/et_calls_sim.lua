-- ZeDUI/tools/qa/et_calls_sim.lua  (Nov 25 2026, Build; the director's 9 Equipment and Thermal calls, option 1 on each)
--   CORE    1  the core meter by moodle level (cut from ThermalTab): green only with no moodle; each level its own look
--   WETC    2  wetness in the game's green-to-blue, by the WET moodle's steps
--   PCT     3  the grid reads % as the detail box does
--   WETW    4  the wetness word: the WET moodle's steps and its own words
--   WEAR    5  an empty slot's list: what fits (cut from EquipmentTab), wears by onWearItems; double-click takes off
--   BELT    6  every belt slot shows, folded or open
--   BOTH    7  a two-handed weapon shows dimmed in the off hand, "both hands"
--   CARD    8  Off hand and Two hands are buttons on an equipped weapon's card (cut from ItemCardOrganism)
--   HAND    9  a weapon dropped on the doll's Main / Off box goes to that hand
-- Run from the repo root:  lua51 ZeDUI/tools/qa/et_calls_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]et_calls_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    return b and string.sub(src, a, b + #to - 1) .. "\n" or nil
end
local function has(s, x) return string.find(s, x, 1, true) ~= nil end

local TT = readFile(Z .. "ThermalTab.lua")
local ET = readFile(Z .. "EquipmentTab.lua")
local ED = readFile(Z .. "EquipDoll.lua")
local ICO = readFile(Z .. "ItemCardOrganism.lua")
local IC = readFile(Z .. "ItemCard.lua")
local CW = readFile(Z .. "ZeD_CharacterWindow.lua")
local EN = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json")

-- the thermal helpers, cut as one block (from the moodle cuts to isWetGetter)
local COLD, COOL, NORM, WARM, HOT = { n = "cold", r = 0, g = 0, b = 1 }, { n = "cool", r = 0, g = 1, b = 1 },
    { n = "norm", r = 0, g = 1, b = 0 }, { n = "warm", r = 1, g = 1, b = 0 }, { n = "hot", r = 1, g = 0, b = 0 }
ZeD = { ThermalTab = {}, T = { tempCold = COLD, tempCool = COOL, tempNorm = NORM, tempWarm = WARM, tempHot = HOT } }
local tsrc = cut(TT, "local HYPO_CUTS  = { 36.5, 35, 30, 25 }", "local function isWetGetter(g)")
check("thermal helpers found", tsrc ~= nil)
if tsrc then
    local fn, e = loadstring(tsrc .. " end", "thermal")
    check("thermal helpers load", fn ~= nil, e)
    if fn then fn() end
end
local TH = ZeD.ThermalTab

print("-- CORE")
if TH.coreLook then
    local function look(c) local lit, col, lv = TH.coreLook(c); return lit, col and col.n, lv end
    local lit, col, lv = look(37.0)
    check("CORE: 37.0, no moodle: green, 5 lit", col == "norm" and lit == 5 and lv == 0)
    lit, col, lv = look(36.2)
    check("CORE: 36.2 is Hypothermia 1, not green", lv == -1 and col ~= "norm" and lit == 4, col)
    lit, col, lv = look(37.3)
    check("CORE: 37.3, no moodle: green", lv == 0 and col == "norm", col)
    check("CORE: 36.5 exactly: none", TH.coreLevel(36.5) == 0)
    check("CORE: 37.5 exactly: none", TH.coreLevel(37.5) == 0)
    check("CORE: 34.9 Hypothermia 2", TH.coreLevel(34.9) == -2)
    check("CORE: 29.9 Hypothermia 3", TH.coreLevel(29.9) == -3)
    check("CORE: 24.9 Hypothermia 4", TH.coreLevel(24.9) == -4)
    check("CORE: 37.6 Hyperthermia 1", TH.coreLevel(37.6) == 1)
    check("CORE: 39.1 Hyperthermia 2", TH.coreLevel(39.1) == 2)
    check("CORE: 40.1 Hyperthermia 3", TH.coreLevel(40.1) == 3)
    check("CORE: 41.5 Hyperthermia 4", TH.coreLevel(41.5) == 4)
    local seen, distinct = {}, true
    for _, c in ipairs({ 20, 28, 33, 36, 37, 38, 39.5, 40.5, 42 }) do
        local l = TH.coreLook(c)
        if seen[l] then distinct = false end
        seen[l] = true
    end
    check("CORE: every level its own segments (Hypothermia 3 and 4 apart)", distinct)
end
check("CORE: the meter draws coreLook", has(TT, "local lit, col = ZeD.ThermalTab.coreLook(data.coreTemp,"))

print("-- WETC / WETW")
if TH.wetColor then
    check("WETC: dry is the green", TH.wetColor(0.05) == NORM)
    check("WETC: soaked is the blue", TH.wetColor(0.95) == COLD)
    check("WETC: never the hot red", TH.wetColor(1) ~= HOT)
    check("WETW: 0.10 Dry", TH.wetWordKey(0.10) == "IGUI_Temp_Dry")
    check("WETW: 0.15 the moodle's first step", TH.wetWordKey(0.15) == "Moodles_Wet_lvl1")
    check("WETW: 0.45 Wet", TH.wetWordKey(0.45) == "Moodles_Wet_lvl2")
    check("WETW: 0.75 Soaking", TH.wetWordKey(0.75) == "Moodles_Wet_lvl3")
    check("WETW: 0.95 Drenched", TH.wetWordKey(0.95) == "Moodles_Wet_lvl4")
end
check("WETC: the figure", has(TT, '(view.id == "wetness") and ZeD.ThermalTab.wetColor(uiVal) or getThermalColor(uiVal)'))
check("WETC: the grid", has(TT, '(view.id == "wetness") and ZeD.ThermalTab.wetColor(fillPct) or getThermalColor(fillPct)'))
check("WETC: the detail rows", has(TT, "wet and ZeD.ThermalTab.wetColor(uiVal) or getThermalColor(uiVal)"))
check("WETW: the detail rows' word", has(TT, "getText(wet and ZeD.ThermalTab.wetWordKey(uiVal) or F.scaleWord("))

print("-- PCT")
check("PCT: the grid reads %", has(TT, 'valStr = math.floor(fillPct * 100 + 0.5) .. "%"'))
check("PCT: no 0.59 left", not has(TT, 'string.format("%.2f", uiVal)'))

print("-- WEAR")
local wsrc = cut(ET, "local function _wornLocOf(item)", "ZeD.EquipmentTab.DOUBLE_MS = 300")
check("WEAR: found", wsrc ~= nil)
if wsrc then
    local LOCATION_TO_SLOT = { hat = { gi = 1, si = 1 }, tshirt = { gi = 2, si = 1 } }
    local EQUIP_GROUPS = { { slots = { { type = "HAT" } } }, { slots = { { type = "INR" } } } }
    local wearCalls, menu = {}, nil
    instanceof = function(o, c) return o and o._cls == c end
    getText = function(k) return k end
    getMouseX, getMouseY = function() return 0 end, function() return 0 end
    ISInventoryPaneContextMenu = {
        onWearItems = function(items, pn) wearCalls[#wearCalls + 1] = items[1] end,
        OnPrimaryWeapon = function(items) wearCalls[#wearCalls + 1] = "pri:" .. items[1].n end,
        OnTwoHandsEquip = function(items) wearCalls[#wearCalls + 1] = "two:" .. items[1].n end,
        OnSecondWeapon = function(items) wearCalls[#wearCalls + 1] = "sec:" .. items[1].n end,
    }
    ISContextMenu = { get = function()
        menu = { opts = {} }
        function menu:addOption(name, target, fn, a, b) local o = { name = name, target = target, fn = fn, a = a, b = b }; self.opts[#self.opts + 1] = o; return o end
        return menu end }
    ZeD = { Atoms = { safeGet = function(o, m, ...) local f = o and o[m]; if not f then return nil end; return f(o, ...) end },
            EquipmentTab = { stillOn = function(p, it) return it.on == true end },
            EquipDoll = { isDollKey = function(k) return k:sub(1, 5) == "doll:" end, slotForLoc = function(loc) return ({ hat = "head", tshirt = "torso" })[loc] end } }
    local fn, e = loadstring("local LOCATION_TO_SLOT, EQUIP_GROUPS = ...\n" .. wsrc, "wear")
    check("WEAR: loads", fn ~= nil, e)
    if fn then
        fn(LOCATION_TO_SLOT, EQUIP_GROUPS)
        local ETm = ZeD.EquipmentTab
        local function cloth(n, loc, on) return { n = n, on = on, IsClothing = function() return true end, getBodyLocation = function() return loc end, getDisplayName = function() return n end } end
        local function weap(n, two) return { n = n, _cls = "HandWeapon", getCondition = function() return 5 end, isTwoHandWeapon = function() return two end, getDisplayName = function() return n end } end
        local beanie, cap, worn, shirt, bat, axe = cloth("Beanie", "Hat"), cloth("Cap", "base:Hat"), cloth("Hood", "Hat", true), cloth("Shirt", "Tshirt"), weap("Bat", false), weap("Axe", true)
        local bagInv = { getItems = function() return { size = function() return 1 end, get = function(_, i) return cap end } end }
        local bag = { n = "Bag", _cls = "InventoryContainer", getInventory = function() return bagInv end, getDisplayName = function() return "Bag" end }
        local items = { beanie, worn, shirt, bat, axe, bag, cloth("Beanie", "Hat") }
        local inv = { getItems = function() return { size = function() return #items end, get = function(_, i) return items[i + 1] end } end }   -- (items is read at each call)
        local p = { getInventory = function() return inv end }
        local hats = ETm.fitting(p, "HAT")
        local names = {}
        for _, it in ipairs(hats) do names[#names + 1] = it.n end
        table.sort(names)
        check("WEAR: an empty Hat row lists the hats carried, the bag's too, none worn, one of each", table.concat(names, ",") == "Beanie,Cap", table.concat(names, ","))
        check("WEAR: the doll's Head box the same", #ETm.fitting(p, "doll:head") == 2)
        check("WEAR: the shirt fits Inner", ETm.fits("INR", shirt) and not ETm.fits("HAT", shirt))
        check("WEAR: a hand slot lists weapons", #ETm.fitting(p, "PRI") == 2 and #ETm.fitting(p, "doll:off") == 2)
        local win = { playerNum = 0, _playerObj = p }
        ETm.openWearMenu(win, "HAT", 1, 1)
        check("WEAR: the menu has a line each", menu and #menu.opts == 2)
        if menu and menu.opts[1] then menu.opts[1].fn(menu.opts[1].target, menu.opts[1].a, menu.opts[1].b) end
        check("WEAR: a pick wears by onWearItems", wearCalls[1] == beanie or wearCalls[1] == cap)
        items = {}
        ETm.openWearMenu(win, "HAT", 1, 1)
        check("WEAR: nothing fits: the game's None, grayed", menu and #menu.opts == 1 and menu.opts[1].name == "IGUI_None" and menu.opts[1].notAvailable == true)
        wearCalls = {}
        ETm.toHand(axe, 0, true); ETm.toHand(bat, 0, true); ETm.toHand(bat, 0, false)
        check("HAND: main hand: two-handed to both, else primary; off hand: second", table.concat(wearCalls, ",") == "two:Axe,pri:Bat,sec:Bat", table.concat(wearCalls, ","))
    end
end
check("WEAR: a single click waits for a second; two take it off", has(ET, "ZeD.EquipmentTab.takeOff(win, zone.item)") and has(ET, "win._equipClickWait = { type = zone.type, item = zone.item, t = now }"))
check("WEAR: the waiting click opens its card once the time is up", has(ET, "if not win._equipSelected then selectSlot(win, cw1.type) end"))
check("WEAR: list empty rows get zones", has(ET, "ez.x, ez.y, ez.w, ez.h, ez.type = x, drawY, contentW, T.rowH, s.type"))
check("WEAR: mouse: press then release opens the list", has(CW, "if ez then win._wearPress = ez.type; return true end") and has(CW, "ZeD.EquipmentTab.openWearMenu(win, wp,"))
check("WEAR: pad: A on an empty doll box or row", select(2, string.gsub(CW, "onActivate = _equipEmptyOnActivate", "")) == 2)

print("-- BELT")
local bsrc = cut(ET, "local function _beltSlots(win, expanded)", "\nend\n")
check("BELT: every slot, folded too", bsrc ~= nil and not has(bsrc, "if expanded then return slots end") and has(bsrc, "return slots"))

print("-- BOTH")
check("BOTH: the list's SEC row keeps the weapon as bothHands", has(ET, "if sec == pri then groups[5].slots[si].bothHands = pri"))
check("BOTH: drawn dimmed, the words alone so a long name cannot cut them (QA's pictures)", has(ET, 'local name = ZeD.tr("UI_ZeD_Equip_BothHands", ""):gsub("^%s+", ""):gsub("%s+$", "")'))
check("BOTH: the doll's Off box", has(ED, "elseif off then out.offBoth = off end") and has(ED, 'if key == "doll:off" and data.offBoth then'))
check("BOTH: EN words", has(EN, '"UI_ZeD_Equip_BothHands": "%1 (both hands)"'))

print("-- CARD")
local csrc = cut(ICO, "local function dropVerb(playerObj)", "\nend\n")
local hsrc = cut(ICO, "local function headerVerbsForContext(ctx, item, playerObj)", "\nend\n")
local catsrc = cut(ICO, "local function categoryOf(item)", "\nend\n")
local sgsrc = cut(ICO, "local function safeGet(item, m, ...)", "\nend\n")
check("CARD: found", csrc and hsrc and catsrc and sgsrc)
if csrc and hsrc and catsrc and sgsrc then
    local cat = "Weapon"
    ZeD = { ItemCard = { verbText = function(id) return id end, eatOff = function() return nil end },
            InventoryRenderer = { carWindowShut = function() return false end } }
    local fn, e = loadstring(sgsrc .. "local function categoryOf(item) return item._cat end\n" .. csrc .. hsrc .. "\nreturn headerVerbsForContext", "card")
    check("CARD: loads", fn ~= nil, e)
    local hv = fn and fn()
    if hv then
        local gun = { _cat = "Weapon", isTwoHandWeapon = function() return true end }
        local function ids(pri, sec)
            local p = { getPrimaryHandItem = function() return pri end, getSecondaryHandItem = function() return sec end }
            local out = {}
            for _, v in ipairs(hv("equipped", gun, p)) do out[#out + 1] = v.id end
            return table.concat(out, ",")
        end
        check("CARD: in the main hand: Off hand, Two hands", ids(gun, nil) == "UNEQUIP,OFF HAND,TWO HANDS,DROP,MORE", ids(gun, nil))
        check("CARD: in both: Off hand only", ids(gun, gun) == "UNEQUIP,OFF HAND,DROP,MORE", ids(gun, gun))
        check("CARD: in the off hand: Two hands", ids(nil, gun) == "UNEQUIP,TWO HANDS,DROP,MORE", ids(nil, gun))
        local knife = { _cat = "Weapon", isTwoHandWeapon = function() return false end, isRequiresEquippedBothHands = function() return false end }
        local kp = { getPrimaryHandItem = function() return knife end, getSecondaryHandItem = function() return nil end }
        local ko = {}
        for _, v in ipairs(hv("equipped", knife, kp)) do ko[#ko + 1] = v.id end
        check("CARD: a knife: Off hand, no Two hands (the game's rule)", table.concat(ko, ",") == "UNEQUIP,OFF HAND,DROP,MORE", table.concat(ko, ","))
        local coat = { _cat = "Clothing" }
        local p = { getPrimaryHandItem = function() return nil end, getSecondaryHandItem = function() return nil end }
        local out = {}
        for _, v in ipairs(hv("equipped", coat, p)) do out[#out + 1] = v.id end
        check("CARD: a worn coat: no hand buttons", table.concat(out, ",") == "UNEQUIP,DROP,MORE")
    end
end
check("CARD: Two hands runs the game's OnTwoHandsEquip", has(IC, 'elseif label == "TWO HANDS" then') and has(IC, "CM.OnTwoHandsEquip(items, playerNum)"))
check("CARD: the 220 card keeps them where they fit", has(ICO, "if v.keepCompact then"))
check("CARD: EN words", has(EN, '"UI_ZeD_Card_VerbTwoHands": "Two hands"') and has(EN, '"UI_ZeD_Card_HelpTwoHands"'))

print("-- HAND")
check("HAND: the hand boxes take drops", has(ED, 'if key == "doll:main" or key == "doll:off" then slotBox(rects, bx, by, b, b).id = key:sub(6) end'))
check("HAND: a weapon goes to that hand", has(ED, "ZeD.EquipmentTab.toHand(item, pn, main)"))

print("-- QA's reads (Nov 25 2026)")
check("READ 1: a list belt row's double-click takes it off", has(ET, "function ZeD.EquipmentTab.beltRowClick(win, zone)") and has(CW, "if ZeD.EquipmentTab.beltRowClick(win, zone) then return true end"))
check("READ 2: Two hands as the game offers it", has(ICO, 'safeGet(item, "isTwoHandWeapon") == true or safeGet(item, "isRequiresEquippedBothHands") == true'))
check("READ 3: the meter reads the moodles", has(TT, "ZeD.ThermalTab.coreLook(data.coreTemp, ZeD.ThermalTab.moodleLevel(win._playerObj))") and has(TT, "MoodleType.HYPOTHERMIA"))
check("READ 4: the grid % clamped as the rows", has(TT, 'valStr = math.floor(fillPct * 100 + 0.5) .. "%"'))
check("READ 5: a stale click wait is dropped, and a tab switch clears it", has(ET, "if age > ZeD.EquipmentTab.DOUBLE_MS + 500 then") and has(CW, "win._equipSelected = nil; win._equipClickWait = nil end"))

print("et_calls_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
