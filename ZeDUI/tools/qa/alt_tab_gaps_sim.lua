-- ZeDUI/tools/qa/alt_tab_gaps_sim.lua  (Nov 7 2026, Build; punch list 109): the alt-tab gaps, with no game running.
--   * What the game lists (RecipeIndex.lua) on stub recipes shaped as the game's 42.21 classes (CraftRecipe,
--     RequiredSkill, script Item with getUsedInRecipes, the world's SeeNotLearntRecipe, OnAddToMenu through
--     callLuaBool): the item card's rows from the game's own list for the item, with See Not Known Recipes off a
--     must-learn recipe not learned left out (item card, skill card, Craft tab), a failed OnAddToMenu check left out
--     (the debug piano), Known / Unknown kept until the known recipes or a level change, known first, the cap and
--     the rest's count, the press opening the game's own way in with "*", the skill index rebuilt when the game's
--     recipe count changes, and the skill card's lines.
--   * Recipes the game teaches by itself on the skill card: by preset (Vanilla Access only), read from Settings.lua.
--   * The item card's controller stops (ItemCard.lua): a "Used to make" row is a stop only inside the body's view,
--     and its title is a section Down scrolls to.
--   * The watch's parked speed controls (ZeD_Watch.lua): their visible flag stays on in single player (the game's
--     Pause on Focus Loss needs it) and off on a server.
-- What it can't show is how it looks and the game's own focus pause: the in-game list in
-- ZeDUI/qa/CHECK_alt_tab_gaps_20261107.md.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/alt_tab_gaps_sim.lua
-- It prints FAIL lines and a last line "alt_tab_gaps_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]alt_tab_gaps_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end

Events = setmetatable({}, { __index = function(t, k)
    local e = { fns = {} }
    e.Add = function(fn) e.fns[#e.fns + 1] = fn end
    e.Remove = noop
    rawset(t, k, e)
    return e
end })
require = function() return nil end
local CLOCK = 0
getTimestampMs = function() return CLOCK end
local function tick(ms) CLOCK = CLOCK + (ms or 1000) end

local EXTRAS = {}
ZeD = {
    tr = function(k, ...)
        local a = { ... }
        local s = k
        for i = 1, #a do s = s .. ":" .. tostring(a[i]) end
        return s
    end,
    SkillsTab = { addExtras = function(id, def) EXTRAS[id] = def end },
}

-- ---------------------------------------------------------------------------
-- THE GAME (stubs shaped as the 42.21 classes)
-- ---------------------------------------------------------------------------
local SEE = false   -- the world's See Not Known Recipes
getSandboxOptions = function()
    return { getOptionByName = function(_, n)
        if n == "SeeNotLearntRecipe" then return { getValue = function() return SEE end } end
        return nil
    end }
end
function debugTest(param) return false end          -- the game's (isDebugEnabled, off)
function barTest(param) return param.shouldShowAll == true end
callLuaBool = function(name, params) return _G[name](params) end

local function perk(id) return { getId = function() return id end, getName = function() return id .. "Name" end } end
local CARP, COOK = perk("Woodwork"), perk("Cooking")
local ONADD = {}
local function recipe(name, display, takes, learn, skills, onAdd)
    local rs = {}
    for _, s in ipairs(skills or {}) do
        rs[#rs + 1] = { getPerk = function() return s[1] end, getLevel = function() return s[2] end }
    end
    return {
        takes = takes,
        getName = function() return name end,
        getTranslationName = function() return display end,
        needToBeLearn = function() return learn or false end,
        getRequiredSkillCount = function() return #rs end,
        getRequiredSkill = function(_, i) return rs[i + 1] end,
        getOnAddToMenu = function() return onAdd end,
    }
end
local R = {
    plank   = recipe("SawPlank", "Saw Planks", { "Base.Log", "Base.Saw" }, false, { { CARP, 1 } }),
    stool   = recipe("MakeStool", "Make Stool", { "Base.Plank", "Base.Nails", "Base.Saw" }, true, { { CARP, 3 } }),
    table_  = recipe("MakeTable", "Make Table", { "Base.Plank", "Base.Saw" }, false, { { CARP, 3 } }),
    secret  = recipe("MakeSecret", "Secret Shelf", { "Base.Plank", "Base.Saw" }, true, { { CARP, 3 } }),
    piano   = recipe("DebugPiano", "Piano", { "Base.Saw" }, false, { { CARP, 3 } }, "debugTest"),
    bar     = recipe("BarElement", "Bar Element", { "Base.Saw" }, false, nil, "barTest"),
    stew    = recipe("MakeStew", "Make Stew", { "Base.Pot", "Base.Carrots" }, false, { { COOK, 2 } }),
    wall    = recipe("BuildWall", "Wooden Wall", { "Base.Plank", "Base.Saw" }, false, { { CARP, 4 } }),
}
local CRAFT = { R.plank, R.stool, R.table_, R.secret, R.piano, R.bar, R.stew }
local BUILD = { R.wall, R.table_ }   -- (MakeTable in both lists: indexed once)
local function byName(l, n) for _, r in ipairs(l) do if r:getName() == n then return r end end return nil end
ScriptManager = { instance = {
    getAllCraftRecipes = function() return list(CRAFT) end,
    getAllBuildableRecipes = function() return list(BUILD) end,
    getCraftRecipe = function(_, n) return byName(CRAFT, n) end,
    getBuildableRecipe = function(_, n) return byName(BUILD, n) end,
} }

-- the character: Woodwork 3, knows no learned recipe yet
local LEVEL = { Woodwork = 3, Cooking = 0 }
local KNOWN = {}
local ASKED = 0   -- isRecipeKnown asked (the kept answers)
local player = {
    getPerkLevel = function(_, pk) return LEVEL[pk:getId()] or 0 end,
    isRecipeKnown = function(_, r) ASKED = ASKED + 1; return KNOWN[r:getName()] or false end,
    isRecipeActuallyKnown = function(_, r) return KNOWN[r:getName()] or false end,
    getKnownRecipes = function()
        local n = {}
        for k, v in pairs(KNOWN) do if v then n[#n + 1] = k end end
        return list(n)
    end,
}
-- a script item: the game's getUsedInRecipes(character) (Item.java, 42.21): every recipe that takes it, a
-- must-learn one not learned dropped while See Not Known Recipes is off
local function scriptItem(ft)
    return { getUsedInRecipes = function(_, p)
        local out = {}
        for _, l in ipairs({ CRAFT, BUILD }) do
            for _, r in ipairs(l) do
                for _, t in ipairs(r.takes) do
                    if t == ft then
                        if not (r:needToBeLearn() and not SEE and not p:isRecipeActuallyKnown(r)) then out[#out + 1] = r:getName() end
                    end
                end
            end
        end
        return list(out)
    end }
end

local OPENED = {}
ISEntityUI = {
    OpenHandcraftWindow = function(p, iso, q, ign, rec, itemString) OPENED[#OPENED + 1] = { "craft", rec and rec:getName(), itemString, q } end,
    OpenBuildWindow = function(p, iso, q, ign, rec, itemString) OPENED[#OPENED + 1] = { "build", rec and rec:getName(), itemString, q } end,
}

-- (the recipe checks run as one part: on older code one that throws is a FAIL, and the rest still run)
local okRecipes, errRecipes = pcall(function()
dofile(ROOT .. "42/media/lua/client/ZeD/RecipeIndex.lua")
local RI = ZeD.RecipeIndex
local function names(l)
    local out = {}
    for _, r in ipairs(l) do out[#out + 1] = (r.rec or r).name end
    return table.concat(out, ",")
end
local SAW, PLANK = scriptItem("Base.Saw"), scriptItem("Base.Plank")

local okCard, errCard = pcall(function()
section("Used to make: the game's own list, as the game shows it")
local rows, more = RI.forCard(player, SAW, 10)
check("See Not Known Recipes off: a must-learn recipe not learned is left out (the stool)", not names(rows):find("MakeStool"), names(rows))
check("a failed OnAddToMenu check is left out (the debug piano)", not names(rows):find("DebugPiano"), names(rows))
check("a check that passes with shouldShowAll stays (the bar element)", names(rows):find("BarElement") ~= nil, names(rows))
check("the rest: plank, table, wall", names(rows):find("SawPlank") and names(rows):find("MakeTable") and names(rows):find("BuildWall"), names(rows))
check("a recipe in both lists once", select(2, names(rows):gsub("MakeTable", "")) == 1, names(rows))
check("an item no recipe takes: none", #RI.forCard(player, scriptItem("Base.Rock"), 6) == 0)
check("no script item: none", #RI.forCard(player, nil, 6) == 0)
SEE = true
tick()
rows = RI.forCard(player, SAW, 10)
check("See Not Known Recipes on: the stool shows, Unknown", names(rows):find("MakeStool") ~= nil, names(rows))
local stoolKnown
for _, r in ipairs(rows) do if r.rec.name == "MakeStool" then stoolKnown = r.known end end
check("... and Unknown", stoolKnown == false)
SEE = false
tick()
KNOWN.MakeStool = true
rows, more = RI.forCard(player, SAW, 3)
check("learned, option off: the stool shows", names(rows):find("MakeStool") ~= nil, names(rows))
check("the card's rows: the cap and the rest's count", #rows == 3 and more == 2, tostring(#rows) .. "/" .. tostring(more))
check("known first, then by name", rows[1].known and rows[1].rec.displayName == "Bar Element" and rows[2].rec.displayName == "Make Stool"
    and rows[3].rec.displayName == "Make Table", names(rows))
local all = RI.forCard(player, SAW, 10)
check("the unknown one last (the wall needs Woodwork 4)", all[#all].rec.name == "BuildWall" and all[#all].known == false, names(all))

section("Known or Unknown kept until the character changes")
ASKED = 0
RI.forCard(player, SAW, 10)
tick(100)
RI.forCard(player, SAW, 10)
check("asked again: the kept answers (no recipe asked again)", ASKED == 0, ASKED)
LEVEL.Woodwork = 4
Events.LevelPerk.fns[1]()
tick(1000)
all = RI.forCard(player, SAW, 10)
local wallKnown
for _, r in ipairs(all) do if r.rec.name == "BuildWall" then wallKnown = r.known end end
check("a level gained: asked again, the wall Known", wallKnown == true)
LEVEL.Woodwork = 3
Events.LevelPerk.fns[1]()
tick(1000)

section("A press opens the game's own way in")
local wallRec
for _, r in ipairs(all) do if r.rec.name == "BuildWall" then wallRec = r.rec end end
RI.open(player, rows[2].rec)
RI.open(player, wallRec)
RI.openAll(player, "Base.Saw")
check("a craft recipe: the Craft tab, that recipe, query *", OPENED[1] and OPENED[1][1] == "craft" and OPENED[1][2] == "MakeStool" and OPENED[1][4] == "*")
check("a build recipe: the Build tab, that recipe, query *", OPENED[2] and OPENED[2][1] == "build" and OPENED[2][2] == "BuildWall" and OPENED[2][4] == "*")
check("the rest: the Craft tab with the item searched", OPENED[3] and OPENED[3][1] == "craft" and OPENED[3][3] == "Base.Saw" and OPENED[3][4] == "*")

end)
check("the item card's recipe checks ran to the end", okCard, errCard)
KNOWN.MakeStool, LEVEL.Woodwork = nil, 3

section("The skill card: what each level still to come needs, as the game shows it")
KNOWN.MakeStool = nil
tick(1000)
local X = EXTRAS.ZeD_RecipeUnlocks
check("registered with the Skills tab's extras", X and X.cardLines ~= nil)
local function cardText(p, lv)
    local flat = {}
    for _, l in ipairs(X.cardLines(player, p, { level = lv, perk = p }) or {}) do flat[#flat + 1] = l.text .. (l.value and ("=" .. l.value) or "") end
    return table.concat(flat, "|")
end
local s = cardText(CARP, 2)
check("option off: level 3 without the stool, the secret shelf or the piano, then level 4",
    s == "UI_ZeD_Skills_UnlockHead|UI_ZeD_Skills_UnlockLevel:3=1|  Make Table|UI_ZeD_Skills_UnlockLevel:4=1", s)
check("the index was built once", RI.builds == 1, RI.builds)
SEE = true
tick(1000)
s = cardText(CARP, 2)
check("option on: the unknown must-learn ones too, never the piano",
    s == "UI_ZeD_Skills_UnlockHead|UI_ZeD_Skills_UnlockLevel:3=3|  Make Stool|  Make Table|  Secret Shelf|UI_ZeD_Skills_UnlockLevel:4=1", s)
SEE = false
tick(1000)
check("at level 4: nothing left", X.cardLines(player, CARP, { level = 4, perk = CARP }) == nil)
check("Cooking at 0: level 2 named", cardText(COOK, 0) == "UI_ZeD_Skills_UnlockHead|UI_ZeD_Skills_UnlockLevel:2=1|  Make Stew", cardText(COOK, 0))
SEE = true
tick(1000)
RI.NEXT_NAMES = 1
local lines = X.cardLines(player, CARP, { level = 2, perk = CARP })
check("past the names: the rest's count", lines and lines[4] and lines[4].text == "  UI_ZeD_Skills_UnlockMore:2", lines and lines[4] and lines[4].text)
RI.NEXT_NAMES = 3
SEE = false
tick(1000)

section("The skill index rebuilt when the game's recipes change")
CRAFT[#CRAFT + 1] = recipe("SawLog", "Saw Log", { "Base.Saw" }, false, { { CARP, 5 } })
cardText(CARP, 2)
check("before the check's interval: not rebuilt yet", RI.builds == 1, RI.builds)
tick(6000)
s = cardText(CARP, 2)
check("after it: rebuilt with the new recipe", RI.builds == 2 and s:find("UnlockLevel:5=1", 1, true) ~= nil, s)
tick(6000)
cardText(CARP, 2)
check("no change: not rebuilt", RI.builds == 2, RI.builds)
Events.OnGameStart.fns[1]()
cardText(CARP, 2)
check("a game starts: rebuilt", RI.builds == 3, RI.builds)

-- ---------------------------------------------------------------------------
-- RECIPES THE GAME TEACHES BY ITSELF: Vanilla Access only (the director, Nov 7 2026)
-- ---------------------------------------------------------------------------
section("Recipes skills teach, by preset")
local SETTINGS_SRC = io.open(ROOT .. "42/media/lua/client/ZeD/Settings.lua"):read("*a")
local presetBlock = SETTINGS_SRC:match("local PRESETS = (%b{})")
check("Settings.lua has the presets' table", presetBlock ~= nil)
local PRESETS = presetBlock and loadstring("local OFF, ON = 1, 2; return " .. presetBlock)() or {}
check("the switch is one of the additions (Custom keeps it)", SETTINGS_SRC:find('"identityStyle", "haloBubble", "autoLearn" }', 1, true) ~= nil)
check("a Vanilla Access player from before keeps the preset (the switch on)",
    SETTINGS_SRC:find('"devicesStyle", "watchStyle", "dashStyle", "identityStyle", "autoLearn"', 1, true) ~= nil)
local function autoRecipe(name, display, any, all)
    local r = recipe(name, display, { "Base.Plank" }, true, nil)
    local function rs(l) local o = {}; for _, s2 in ipairs(l or {}) do o[#o + 1] = { getPerk = function() return s2[1] end, getLevel = function() return s2[2] end } end; return o end
    local a, b = rs(any), rs(all)
    r.getAutoLearnAnySkillCount = function() return #a end
    r.getAutoLearnAnySkill = function(_, i) return a[i + 1] end
    r.getAutoLearnAllSkillCount = function() return #b end
    r.getAutoLearnAllSkill = function(_, i) return b[i + 1] end
    return r
end
CRAFT[#CRAFT + 1] = autoRecipe("Birdhouse", "Birdhouse", { { CARP, 5 } })
CRAFT[#CRAFT + 1] = autoRecipe("Crate", "Crate", { { CARP, 5 }, { COOK, 3 } })
CRAFT[#CRAFT + 1] = autoRecipe("Smoker", "Smoker", nil, { { CARP, 6 }, { COOK, 3 } })
RI.reset()
SEE = true   -- (a world that shows unknown recipes: the game would list these)
tick(1000)
local SWITCH = 1
ZeD.Settings = { autoLearnOn = function() return SWITCH == 2 end }
local function taughtText(p, lv)
    local out = {}
    local inTaught = false
    for _, l in ipairs(X.cardLines(player, p, { level = lv, perk = p }) or {}) do
        if l.text == "UI_ZeD_Skills_TaughtHead" then inTaught = true end
        if inTaught then out[#out + 1] = l.text .. (l.value and ("=" .. l.value) or "") end
    end
    return table.concat(out, "|")
end
local want = { [1] = false, [2] = false, [3] = true }
local NAME = { "Vanilla", "Vanilla Plus", "Vanilla Access" }
for i = 1, 3 do
    SWITCH = (PRESETS[i] and PRESETS[i].autoLearn) or 1
    s = taughtText(CARP, 4)
    if want[i] then
        check(NAME[i] .. ": the switch is on", SWITCH == 2, SWITCH)
        check(NAME[i] .. ": the skill card lists them (level 5 named, then 6)",
            s == "UI_ZeD_Skills_TaughtHead|UI_ZeD_Skills_UnlockLevel:5=2|  Birdhouse|  Crate|UI_ZeD_Skills_UnlockLevel:6=1", s)
    else
        check(NAME[i] .. ": the switch is off", SWITCH == 1, SWITCH)
        check(NAME[i] .. ": the skill card keeps them hidden, as the game", s == "", s)
    end
end
SWITCH = 2
check("Custom, on: listed under the other skill too (any or all)", taughtText(COOK, 0) == "UI_ZeD_Skills_TaughtHead|UI_ZeD_Skills_UnlockLevel:3=2|  Crate|  Smoker", taughtText(COOK, 0))
SEE = false
tick(1000)
check("Vanilla Access, See Not Known Recipes off: the ones not learned stay hidden, as the game",
    taughtText(CARP, 4) == "", taughtText(CARP, 4))
KNOWN.Birdhouse = true
tick(1000)
check("... a learned one shows", taughtText(CARP, 4) == "UI_ZeD_Skills_TaughtHead|UI_ZeD_Skills_UnlockLevel:5=1|  Birdhouse", taughtText(CARP, 4))
KNOWN.Birdhouse = nil
SEE = true
tick(1000)
SWITCH = 1
check("Custom, off: hidden", taughtText(COOK, 0) == "")
check("off: the levels' needs still show", X.cardLines(player, CARP, { level = 2, perk = CARP })[1].text == "UI_ZeD_Skills_UnlockHead")
ZeD.Settings = nil
check("no ZeD setup read: hidden", taughtText(CARP, 4) == "")

-- ---------------------------------------------------------------------------
-- THE CRAFT TAB LISTS WHAT THE GAME LISTS
-- ---------------------------------------------------------------------------
section("The Craft tab: only what the game lists")
SEE = false
tick(1000)
ZeD.CraftingCore = {
    prebakeInputs = function() return {} end, prebakeOutputs = function() return {} end,
    prebakeSkills = function() return {} end, resolveCategory = function() return "Carpentry" end,
    getPerkType = function(n) return CARP end, carryStatus = noop,
}
ZeD.textCase = function(x) return x end
Perks = { None = "None" }
CRAFT = { R.plank, R.stool, R.secret, R.piano, R.table_ }
local okC, errC = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/CraftingTab.lua")
check("the Craft tab loads on the stubs", okC, errC)
if okC then
    local data = ZeD.CraftingTab.gatherData(player, {})
    local got = {}
    for _, rd in ipairs(data.recipes or {}) do got[#got + 1] = rd.entry.name end
    local g = table.concat(got, ",")
    check("option off: no unknown must-learn recipe, no piano", not g:find("MakeStool") and not g:find("MakeSecret") and not g:find("DebugPiano") and g:find("SawPlank") ~= nil, g)
    SEE = true
    tick(1000)
    data = ZeD.CraftingTab.gatherData(player, {})
    got = {}
    for _, rd in ipairs(data.recipes or {}) do got[#got + 1] = rd.entry.name end
    g = table.concat(got, ",")
    check("option on: the must-learn ones too, still no piano", g:find("MakeStool") and g:find("MakeSecret") and not g:find("DebugPiano"), g)
    SEE = false
end

end)
check("the recipe checks ran to the end", okRecipes, errRecipes)

-- ---------------------------------------------------------------------------
-- THE ITEM CARD'S CONTROLLER STOPS
-- ---------------------------------------------------------------------------
section("The item card: a row is a stop only in view")
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
ISPanel = { derive = function() return {} end }
local savedRI = ZeD.RecipeIndex
ZeD = setmetatable({ Atoms = { safeGet = noop, wrapText = noop }, ItemCard = {} }, { __index = function() return stub end })
local okI, errI = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ItemCard.lua")
check("the item card file loads on the stubs", okI, errI)
if okI then
    local IC = ZeD.ItemCard
    check("a row wholly inside the body: in view", IC.rowInView and IC.rowInView(100, 20, 50, 400) == true)
    check("a row below the body: out", IC.rowInView and IC.rowInView(390, 20, 50, 400) == false)
    check("a row under the sticky head: out", IC.rowInView and IC.rowInView(40, 20, 50, 400) == false)
    local card = setmetatable({ item = {}, _zoneDockRects = {}, getAbsoluteY = function() return 1000 end, _scrollPixels = 30,
        _foldHitRects = { { y = 1300 } }, _makesSecY = 1200,
        _makeRects = { { x = 0, y = 1100, w = 10, h = 10, id = "make_1", inView = true },
                       { x = 0, y = 1500, w = 10, h = 10, id = "make_2", inView = false } } }, { __index = ZeD_ItemCard })
    local els = card:getZoneDockElements()
    local ids = {}
    for _, e in ipairs(els) do ids[#ids + 1] = e.id end
    check("only the row in view is a stop", #els == 1 and els[1].id == "make_1", table.concat(ids, ","))
    local ys = card:getDisclosureYs()
    check("the section's title is a place Down scrolls to, in order", #ys == 2 and ys[1] == 230 and ys[2] == 330,
        table.concat(ys, ","))
end

-- ---------------------------------------------------------------------------
-- THE WATCH'S PARKED SPEED CONTROLS
-- ---------------------------------------------------------------------------
section("The parked speed controls keep the game's focus pause")
ZeD_Panel = { derive = function() return {} end }
ZeD = setmetatable({ tr = function(k) return k end, trDefaults = noop, Safe = { register = noop, on = function() return false end } },
                   { __index = function() return stub end })
local CLIENT = false
isClient = function() return CLIENT end
getSpecificPlayer = function() return {} end
local sc = { vis = true, y = 20 }
function sc:isVisible() return self.vis end
function sc:setVisible(v) self.vis = v end
function sc:getY() return self.y end
function sc:setY(v) self.y = v end
function sc:getCurrentGameSpeed() return 1 end
UIManager = { getClock = function() return nil end, getSpeedControls = function() return sc end }
local ok, err = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ZeD_Watch.lua")
check("the watch file loads on the stubs", ok, err)
if ok then
    -- one frame of the watch (it errors later, past the parking, on the stubs: that is fine)
    pcall(ZeD_Watch.prerender, setmetatable({ playerNum = 0 }, { __index = function() return stub end }))
    check("single player: parked off-screen", sc.y == -4000, sc.y)
    check("single player: the flag stays on (the game's Pause on Focus Loss reads it)", sc.vis == true, sc.vis)
    CLIENT = true
    pcall(ZeD_Watch.prerender, setmetatable({ playerNum = 0 }, { __index = function() return stub end }))
    check("on a server: the flag goes off", sc.vis == false, sc.vis)
    CLIENT = false
    sc.vis = false
    pcall(ZeD_Watch.prerender, setmetatable({ playerNum = 0 }, { __index = function() return stub end }))
    check("back in single player: on again", sc.vis == true, sc.vis)
end

print("alt_tab_gaps_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
