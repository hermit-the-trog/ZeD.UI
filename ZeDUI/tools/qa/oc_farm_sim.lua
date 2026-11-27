-- ZeDUI/tools/qa/oc_farm_sim.lua  (Nov 26 2026, Build; QA's farm card map, 2026-11-26_map_cards_farm_animals.md)
-- Loads the real ObjectCardFarm.lua over stubs of the game's farming objects and checks QA's proven farm bugs:
--   FA2  the water word's mark, the garden cell's mark and the summary follow vanilla's getWaterLvlColor (the crop's
--        own need, calcWater, from Farming 3) for every level, need, stage and skill
--   FA3  the pad opens on Water when it is the main verb, Sow on plowed land, else the back button: never Fertilize
--   FA4  the Dig question remembers the object it asked about, goes when the card shows another, and Yes checks it
--   FA12 Yes with the shovel gone queues nothing and says why
--   FA11 MoreAt and ListAnd in every UI.json; every garden label unique; a trampled plant's tag is the game's word
-- The game's rules are read from the game's own files when they are there (E:\Project Zomboid, or PZ_LUA), else
-- from the copies below. Run from the repo root:  lua51 ZeDUI/tools/qa/oc_farm_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_farm_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local Z = ROOT .. "42/media/lua/client/ZeD/"
local PZ = os.getenv("PZ_LUA") or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("oc_farm_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed > 0 and 1 or 0)
end
local function readFile(p, must)
    local f = io.open(p, "rb")
    if not f then if must then error("missing " .. p) end return nil end
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- the game's rules: calcWater and getWaterLvlColor
-- ---------------------------------------------------------------------------
farming_vegetableconf = { props = {} }
local vc = readFile(PZ .. "server/Farming/farming_vegetableconf.lua")
local calcSrc = vc and vc:match("\n(farming_vegetableconf%.calcWater = function.-\nend\n)")
if calcSrc then
    assert(loadstring(calcSrc))()
else
    farming_vegetableconf.calcWater = function(waterMin, waterLvl)
        if waterLvl and waterMin then
            if waterLvl >= waterMin then return 0
            elseif waterLvl >= math.floor(waterMin / 1.10) then return waterMin - waterLvl
            elseif waterLvl >= math.floor(waterMin / 1.30) then return -1
            else return -2 end
        end
        return 0
    end
end
ISFarmingInfo = {}
function ISFarmingInfo:getGreen(l) l.c = "green" end
function ISFarmingInfo:getRed(l) l.c = "red" end
function ISFarmingInfo:getOrange(l) l.c = "orange" end
function ISFarmingInfo:getWhite(l) l.c = "white" end
local fi = readFile(PZ .. "client/Farming/ISUI/ISFarmingInfo.lua")
local colSrc = fi and fi:match("\n(function ISFarmingInfo%.getWaterLvlColor%(.-\nend\n)")
if colSrc then
    assert(loadstring("local water_rgb = {}\n" .. colSrc))()
else
    function ISFarmingInfo.getWaterLvlColor(plant, farmingLevel)
        local rgb = {}
        if farmingLevel >= 3 and plant:isAlive() then
            if plant.nbOfGrow == 1 then
                rgb.c = "green"
                if plant.waterLvl < plant.waterNeeded then rgb.c = "red" end
            else
                local water = farming_vegetableconf.calcWater(plant.waterNeeded, plant.waterLvl)
                local waterMax = farming_vegetableconf.calcWater(plant.waterLvl, plant.waterNeededMax)
                if water >= 0 and waterMax >= 0 then rgb.c = "green"
                elseif water == -1 or waterMax == -1 then rgb.c = "orange"
                else rgb.c = "red" end
            end
        else rgb.c = "white" end
        return rgb
    end
end
print("(the game's rules from " .. ((calcSrc and colSrc) and "the game's files" or "the sim's copies") .. ")")

-- ---------------------------------------------------------------------------
-- stubs
-- ---------------------------------------------------------------------------
local EN = {}
local enFarm = readFile(PZ .. "shared/Translate/EN/Farming.json")
if enFarm then for k, v in enFarm:gmatch('"(Farming_[%w_]+)"%s*:%s*"([^"]*)"') do EN[k] = v end end
for k, v in pairs({ Farming_Destroyed = "Destroyed", Farming_Dead = "Dead", Farming_Harvested = "Harvested",
    Farming_Rotten = "Rotten", Farming_Carrots = "Carrots", Farming_Cabbages = "Cabbages" }) do
    if not EN[k] then EN[k] = v end
end
local lastHalo = nil
function getText(k, ...) return EN[k] or k end
function getTextOrNull(k) return EN[k] end
Translator = { getLanguage = function() return "EN" end }
HaloTextHelper = { addBadText = function(p, s) lastHalo = s end }
ItemTag = { MAGNIFIER = "m", FERTILIZER = "f", COMPOST = "c", IS_CUTTING = "x" }
function getTexture() return nil end
function getGameTime() return { getMonth = function() return 0 end } end
function instanceof() return false end
local queued = {}
ISTimedActionQueue = { add = function(a) queued[#queued + 1] = a end }
local function act(kind) return { new = function(self, ...) return { kind = kind, args = { ... } } end } end
ISShovelAction = act("shovel"); ISWaterPlantAction = act("water"); ISEquipWeaponAction = act("equip")
ISFertilizeAction = act("fert"); ISHarvestPlantAction = act("harvest"); ISCurePlantAction = act("cure")
local shovelItem = nil
ISFarmingMenu = {
    getShovel = function() return shovelItem end,
    getWaterUsesInteger = function(it) return it and it.uses or 0 end,
    walkToPlant = function() return true end,
}
ISWorldObjectContextMenu = { equip = function(p, hand, it) return it end }
ZeD = {
    T = { positive = { n = "positive" }, warning = { n = "warning" }, danger = { n = "danger" }, textDim = { n = "dim" }, px = function(n) return n end },
    tr = function(k, a, b) return k .. (a and (":" .. tostring(a)) or "") .. (b and (":" .. tostring(b)) or "") end,
    btnCase = function(s) return s end,
}
local def
ZeD.ObjectCards = {
    ui = {}, call = function(o, m, ...) if o and o[m] then return o[m](o, ...) end end, DOT = ".",
    register = function(d) def = d end, LEASH = 6, REFRESH = 15,
    keyOf = function(sq, k) return k .. tostring(sq.id) end, sortTargets = function(l) return l end,
    eachSquare = function() end, cap = function(s) return (s:gsub("^%l", string.upper)) end,
    itemName = function(a, b) return b end,
}
function require() end

local farmSrc = readFile(Z .. "ObjectCardFarm.lua", true)
assert(loadstring(farmSrc, "ObjectCardFarm.lua"))()
check("the farm card registers", def ~= nil)
if not def then done() end

-- the card's own pieces, cut out of the file (locals)
local function cut(pat) return farmSrc:match(pat) end
local wmSrc = cut("\n(local function waterMark%(.-\nend\n)")
local urSrc = cut("\n(local function urgency%(.-\nend\n)")
local glSrc = cut("\n(local labelCache = .-\nlocal function gardenLabel%(.-\nend\n)")
check("FA2 the card has its own water mark (waterMark)", wmSrc ~= nil)
check("FA11 the card has unique garden labels (gardenLabel)", glSrc ~= nil)
local waterMark, urgency, gardenLabel
if wmSrc and urSrc then
    local chunk = assert(loadstring("local PESTS, txt = ...\n" .. wmSrc .. urSrc .. (glSrc or "") .. "\nreturn waterMark, urgency, gardenLabel"))
    waterMark, urgency, gardenLabel = chunk({ { key = "aphidLvl" } }, function(k, fb) return EN[k] or fb or k end)
end

local function plant(o)
    local p = { state = "seeded", waterLvl = 50, waterNeeded = 70, nbOfGrow = 2, typeOfSeed = "Carrots", alive = true,
        mildewLvl = 0, fliesLvl = 0, aphidLvl = 0, slugsLvl = 0, compost = false, hasSeed = false, hasVegetable = false }
    for k, v in pairs(o or {}) do p[k] = v end
    function p:isAlive() return self.alive end
    function p:canHarvest() return false end
    function p:getSquare() return { id = 1 } end
    return p
end

-- ---------------------------------------------------------------------------
-- FA2: every level, need, stage and skill against the game's colour
-- ---------------------------------------------------------------------------
local NAME = { positive = "green", warning = "orange", danger = "red" }
if waterMark then
    local bad, n, first = 0, 0, nil
    for _, need in ipairs({ 70, 80 }) do
        for _, grow in ipairs({ 1, 2, 3, 5 }) do
            for _, alive in ipairs({ true, false }) do
                for skill = 0, 10 do
                    for lvl = 0, 100 do
                        local pl = plant({ waterLvl = lvl, waterNeeded = need, nbOfGrow = grow, alive = alive })
                        local g = ISFarmingInfo.getWaterLvlColor(pl, skill).c
                        local c = waterMark(pl, skill)
                        local mine = c and NAME[c.n] or "white"
                        n = n + 1
                        if mine ~= g then
                            bad = bad + 1
                            first = first or string.format("need %d stage %d alive %s Farming %d water %d: card %s, game %s", need, grow, tostring(alive), skill, lvl, mine, g)
                        end
                    end
                end
            end
        end
    end
    check("FA2 the card's water mark is the game's colour in all " .. n .. " cases", bad == 0, first)
    -- QA's own cases: a stage-2 crop needing 80
    local p65, p60 = plant({ waterLvl = 65, waterNeeded = 80 }), plant({ waterLvl = 60, waterNeeded = 80 })
    check("FA2 need 80 at 65, Farming 3: orange", (waterMark(p65, 3) or {}).n == "warning")
    check("FA2 need 80 at 60, Farming 4: red", (waterMark(p60, 4) or {}).n == "danger")
    check("FA2 below Farming 3: no mark", waterMark(p65, 2) == nil)
    -- the garden cell
    check("FA2 the cell at need 80, water 65, Farming 3: orange", (urgency(p65, false, 3) or {}).n == "warning")
    check("FA2 the cell at need 80, water 60, Farming 3: red", (urgency(p60, false, 3) or {}).n == "danger")
    check("FA2 the cell below Farming 3 on a living plant: no mark", urgency(p65, false, 2) == nil)
    check("FA2 a dead plot's cell stays red at any skill", (urgency(plant({ alive = false }), false, 0) or {}).n == "danger")
end
-- the body draws the mark at Farming 3 (the bar comes at 4)
check("FA2 the word's mark comes from the crop's need (d.waterC)", farmSrc:find("d.waterC = (not d.plowed) and waterMark(plant, d.skill)", 1, true) ~= nil
    and farmSrc:find("waterWord(d.water), d.waterC", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
-- refresh-driven checks: FA3, FA12, FA11 tag
-- ---------------------------------------------------------------------------
CFarmingSystem = { instance = { xp = 4, getXp = function(self) return self.xp end } }
farming_vegetableconf.getObjectName = function(p) return "Young Carrots" end
farming_vegetableconf.props.Carrots = { harvestLevel = 5 }
local inv = { items = {} }
function inv:getFirstTypeRecurse(t) return self.items[t] end
function inv:getFirstTagRecurse(t) return nil end
function inv:getFirstTypeEvalRecurse(t) return nil end
function inv:getItems() local l = {}; for _, v in pairs(self.items) do if v.uses then l[#l + 1] = v end end
    return { size = function() return #l end, get = function(_, i) return l[i + 1] end } end
local player = { getInventory = function() return inv end, getPrimaryHandItem = function() return nil end,
    getSecondaryHandItem = function() return nil end }
local function verb(t, id) for _, v in ipairs(t.verbs or {}) do if v.id == id then return v end end end

check("FA3 the farm card picks its own opening focus", type(def.openFocus) == "function")
if def.openFocus then
    -- QA's case: watered, unripe, fertilizer carried, no water carried
    inv.items = { Fertilizer = { n = "fert" } }
    local t = { obj = plant({ waterLvl = 90 }), sq = { id = 1 } }
    def.refresh(t, player)
    check("FA3 Fertilize is lit in QA's case (the stage is set)", verb(t, "fert") and verb(t, "fert").enabled)
    check("FA3 watered plant, fertilizer carried: the pad opens on back, not Fertilize", def.openFocus(t) == "oc:back", def.openFocus(t))
    -- thirsty with a bottle: Water
    inv.items = { Fertilizer = { n = "fert" }, Bottle = { uses = 10 } }
    t = { obj = plant({ waterLvl = 40 }), sq = { id = 1 } }
    def.refresh(t, player)
    check("FA3 thirsty with water carried: the pad opens on Water", def.openFocus(t) == "oc:verb:water", def.openFocus(t))
    -- a crop needing 80 at 65 needs water too
    t = { obj = plant({ waterLvl = 65, waterNeeded = 80 }), sq = { id = 1 } }
    def.refresh(t, player)
    check("FA3 under the crop's own need: the pad opens on Water", def.openFocus(t) == "oc:verb:water", def.openFocus(t))
    -- thirsty, no water carried: back
    inv.items = { Fertilizer = { n = "fert" } }
    t = { obj = plant({ waterLvl = 40 }), sq = { id = 1 } }
    def.refresh(t, player)
    check("FA3 thirsty, nothing to pour: back, not Fertilize", def.openFocus(t) == "oc:back", def.openFocus(t))
end

-- FA12: the shovel gone between Dig up and Yes
inv.items = {}
shovelItem = { n = "shovel" }
local t = { obj = plant({ waterLvl = 90 }), sq = { id = 1 } }
def.refresh(t, player)
local dig = verb(t, "dig")
check("FA12 Dig up is lit with a shovel and asks first", dig and dig.enabled and dig.confirm ~= nil)
if dig then
    shovelItem = nil
    queued, lastHalo = {}, nil
    dig.run(player, t)
    check("FA12 Yes with the shovel gone queues nothing", #queued == 0, #queued)
    check("FA12 and says why", lastHalo ~= nil and lastHalo:find("UI_ZeD_Farm_NeedsShovel", 1, true) ~= nil, lastHalo)
    shovelItem = { n = "shovel" }
    queued = {}
    dig.run(player, t)
    local sh = queued[#queued]
    check("FA12 with the shovel, Yes queues the dig with the tool", sh and sh.kind == "shovel" and sh.args[2] == shovelItem)
end

-- FA11: a trampled plant's tag
t = { obj = plant({ state = "destroyed", alive = false }), sq = { id = 1 } }
def.refresh(t, player)
local tag = def.pill(t)
check("FA11 a trampled plant's tag is the game's word (Destroyed)", tag == "Destroyed", tag)

-- FA11: unique labels over every crop of the game
local crops, have = {}, {}
for _, f in ipairs({ "farming_vegetableconf_vegetables.lua", "farming_vegetableconf_herbs.lua", "farming_vegetableconf.lua" }) do
    local cropSrc = readFile(PZ .. "server/Farming/" .. f)
    if cropSrc then
        for k in cropSrc:gmatch("\nfarming_vegetableconf%.props%.([%w_]+)%s*=%s*{") do if not have[k] then have[k] = true; crops[#crops + 1] = k end end
        for k in cropSrc:gmatch('\nfarming_vegetableconf%.props%["([%w_]+)"%]%s*=%s*{') do if not have[k] then have[k] = true; crops[#crops + 1] = k end end
    end
end
if #crops == 0 then crops = { "Broccoli", "BroadleafPlantain", "Comfrey", "CommonMallow", "Rosemary", "Roses", "Chives", "Cabbages" } end
for _, k in ipairs(crops) do
    farming_vegetableconf.props[k] = farming_vegetableconf.props[k] or {}
    EN["Farming_" .. k] = EN["Farming_" .. k] or k
end
if gardenLabel then
    local seen, clash = {}, nil
    for _, k in ipairs(crops) do
        local l = gardenLabel(k)
        local n = EN["Farming_" .. k]
        if seen[l] and seen[l] ~= n then clash = clash or (l .. ": " .. seen[l] .. " and " .. n) end
        seen[l] = n
        if #l < 3 and #n >= 3 then clash = clash or ("short label " .. l) end
    end
    check("FA11 every garden label is unique over " .. #crops .. " crops", clash == nil, clash)
    check("FA11 Broccoli and Broadleaf Plantain differ", gardenLabel("Broccoli") ~= gardenLabel("BroadleafPlantain"))
    check("FA11 Rosemary and Roses differ", gardenLabel("Rosemary") ~= gardenLabel("Roses"))
    check("FA11 a short name keeps three letters (Carrots: Car)", gardenLabel("Carrots") == "Car", gardenLabel("Carrots"))
end
check("FA11 the cells draw the unique label", farmSrc:find("label = gardenLabel(plant.typeOfSeed)", 1, true) ~= nil)

-- FA11: MoreAt and ListAnd in every language
local langs = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
    "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local miss = {}
for _, l in ipairs(langs) do
    local s = readFile(ROOT .. "42/media/lua/shared/Translate/" .. l .. "/UI.json")
    if s and not (s:find('"UI_ZeD_Farm_MoreAt": "[^"]*%%1', 1) and s:find('"UI_ZeD_Farm_ListAnd": "[^"]*%%1[^"]*%%2', 1)) then miss[#miss + 1] = l end
end
check("FA11 MoreAt and ListAnd in every UI.json", #miss == 0, table.concat(miss, " "))

-- ---------------------------------------------------------------------------
-- FA7 (the director's call, Nov 26 2026): Treat on aphids sprays every use the plant needs in one press, one walk,
-- as the game's aphids menu (1 to 10 uses; each kills 10 + Farming, SPlantGlobalObject.cureAphids); the other
-- pests stay one use, the only amount the game offers. The game's time: 10 * (uses * 10).
-- ---------------------------------------------------------------------------
do
    local farming = 0
    local fplayer = { getInventory = function() return inv end, getPrimaryHandItem = function() return nil end,
        getSecondaryHandItem = function() return nil end, getPerkLevel = function() return farming end }
    local walks = 0
    local oldWalk = ISFarmingMenu.walkToPlant
    ISFarmingMenu.walkToPlant = function() walks = walks + 1; return true end
    local sprayUses = 20
    local spray = { getType = function() return "GardeningSprayAphids" end, getCurrentUses = function() return sprayUses end }
    local milk = { getType = function() return "GardeningSprayMilk" end, getCurrentUses = function() return 20 end }
    local oldEval = inv.getFirstTypeEvalRecurse
    inv.getFirstTypeEvalRecurse = function(_, ty) return (ty == "GardeningSprayAphids" and spray) or (ty == "GardeningSprayMilk" and milk) or nil end
    inv.items = {}
    local function press(lvl, pestKey, skill, have)
        farming, sprayUses = skill or 0, have or 20
        local t = { obj = plant({ aphidLvl = lvl, mildewLvl = lvl }), sq = { id = 1 } }
        def.refresh(t, fplayer)
        queued, walks = {}, 0
        local pd = nil
        for _, pe in ipairs(t.d.pests) do if pe.def.key == pestKey then pd = pe.def end end
        if t.treat and pd then t.treat(fplayer, pd) end
        local cure = nil
        for _, a in ipairs(queued) do if a.kind == "cure" then cure = a end end
        return cure, walks, t
    end
    local cure, w, t = press(50, "aphidLvl", 0)
    check("FA7 the card has one Treat path for every pest row (t.treat)", t.treat ~= nil)
    check("FA7 heavy aphids (50), Farming 0: one press sprays 5 uses", cure and cure.args[3] == 5, cure and cure.args[3])
    check("FA7 ... with one walk", w == 1, w)
    check("FA7 ... and the game's time for 5 (500)", cure and cure.args[5] == 500, cure and cure.args[5])
    check("FA7 ... the game's cure, Aphids, with the spray", cure and cure.args[6] == "Aphids" and cure.args[2] == spray)
    cure = press(50, "aphidLvl", 3)
    check("FA7 aphids 50 at Farming 3 (13 a use): 4 uses", cure and cure.args[3] == 4, cure and cure.args[3])
    cure = press(100, "aphidLvl", 0)
    check("FA7 aphids 100: the game's cap of 10", cure and cure.args[3] == 10, cure and cure.args[3])
    cure = press(50, "aphidLvl", 0, 3)
    check("FA7 aphids 50, the spray holds 3: 3 uses", cure and cure.args[3] == 3, cure and cure.args[3])
    cure = press(0, "aphidLvl", 0)
    check("FA7 no aphids seen: one use, as before", cure and cure.args[3] == 1 and cure.args[5] == 100, cure and cure.args[3])
    cure = press(50, "mildewLvl", 0)
    check("FA7 mildew stays one use (the game offers only 1)", cure and cure.args[3] == 1 and cure.args[6] == "Mildew", cure and cure.args[3])
    check("FA7 the pest row's Treat goes through t.treat", farmSrc:find("run = pe.spray and function(c, p) t.treat(p, pp.def) end or nil", 1, true) ~= nil)
    ISFarmingMenu.walkToPlant = oldWalk
    inv.getFirstTypeEvalRecurse = oldEval
end

-- ---------------------------------------------------------------------------
-- FA8 (the director's call, Nov 26 2026): Water pours from the container he picked in the card's list; unpicked,
-- or the pick no longer carried, the biggest, as before
-- ---------------------------------------------------------------------------
do
    local function src(name, uses) return { uses = uses, getName = function() return name end } end
    local bottle, jug = src("Water Bottle", 4), src("Water Jug", 20)
    inv.items = { Bottle = bottle, Jug = jug }
    local t = { obj = plant({ waterLvl = 20 }), sq = { id = 1 } }
    def.refresh(t, player)
    check("FA8 both containers are listed", #t.d.water_src == 2, #t.d.water_src)
    local function pour()
        queued = {}
        verb(t, "water").run(player, t)
        for _, a in ipairs(queued) do if a.kind == "water" then return a end end
    end
    local a = pour()
    check("FA8 unpicked: Water pours the biggest (the jug)", a and a.args[2] == jug, a and a.args[2] and a.args[2].getName())
    check("FA8 ... 8 uses, what the plant lacks (the game's rule)", a and a.args[3] == 8, a and a.args[3])
    t.waterPick = bottle
    a = pour()
    check("FA8 picked the bottle: Water pours the bottle", a and a.args[2] == bottle, a and a.args[2] and a.args[2].getName())
    check("FA8 ... its 4 uses", a and a.args[3] == 4, a and a.args[3])
    inv.items = { Jug = jug }
    a = pour()
    check("FA8 the picked bottle gone: back to the biggest", a and a.args[2] == jug, a and a.args[2] and a.args[2].getName())
    check("FA8 the card lists each source with a Use row (farm:water:i) that sets the pick",
        farmSrc:find('fid = "farm:water:" .. i', 1, true) ~= nil and farmSrc:find("run = function(c, p) t.waterPick = item end", 1, true) ~= nil)
    local miss = {}
    for _, l in ipairs(langs) do
        local s = readFile(ROOT .. "42/media/lua/shared/Translate/" .. l .. "/UI.json")
        if s and not (s:find('"UI_ZeD_Farm_WaterFrom": "[^"]', 1) and s:find('"UI_ZeD_Farm_HelpWaterFrom": "[^"]*%%1', 1)) then miss[#miss + 1] = l end
    end
    check("FA8 WaterFrom and HelpWaterFrom in every UI.json", #miss == 0, table.concat(miss, " "))
    inv.items = {}
end

-- ---------------------------------------------------------------------------
-- FA4: the question is tied to the object it asked about (ObjectCards.lua)
-- ---------------------------------------------------------------------------
local oc = readFile(Z .. "ObjectCards.lua", true)
check("FA4 the question remembers the object it asked about", oc:find("key = e.t and e.t.key }", 1, true) ~= nil)
check("FA4 the question goes when the card shows another object", oc:find("if self._confirm and self._confirm.key ~= (t and t.key) then\n        self._confirm = nil", 1, true) ~= nil)
check("FA4 Yes acts only on the object it asked about, still there", oc:find("local same = tNow ~= nil and tNow.key == cf.key", 1, true) ~= nil
    and oc:find("if p and cf.run and same then", 1, true) ~= nil)

done()
