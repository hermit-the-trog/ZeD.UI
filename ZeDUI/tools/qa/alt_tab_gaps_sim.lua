-- ZeDUI/tools/qa/alt_tab_gaps_sim.lua  (Nov 7 2026, Build; punch list 109): the alt-tab gaps, with no game running.
--   * The recipe index (RecipeIndex.lua) on stub recipes shaped as the game's (CraftRecipe, InputScript, script
--     Item, RequiredSkill): the recipes an item goes into (craft and build, an automation-only input left out, a
--     recipe in both lists once), Known / Unknown as the Craft tab's card says it (learned and every skill), known
--     first, the cap and the rest's count, the index built once and rebuilt when the game's recipe count changes,
--     the press opening the game's own Craft / Build way in, and the skill card's lines (each level still to come,
--     the next level's recipes by name).
--   * The watch's parked speed controls (ZeD_Watch.lua): their visible flag stays on in single player (the game's
--     Pause on Focus Loss needs it) and off on a server. On the old code the flag went off in single player too.
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
-- THE GAME'S RECIPES (stubs shaped as the 42.22 classes)
-- ---------------------------------------------------------------------------
local function perk(id) return { getId = function() return id end, getName = function() return id .. "Name" end } end
local CARP, COOK = perk("Woodwork"), perk("Cooking")
local function item(ft) return { getFullName = function() return ft end } end
local function input(types, auto)
    local its = {}
    for _, ft in ipairs(types) do its[#its + 1] = item(ft) end
    return { isAutomationOnly = function() return auto or false end, getPossibleInputItems = function() return list(its) end }
end
local function recipe(name, display, inputs, learn, skills)
    local rs = {}
    for _, s in ipairs(skills or {}) do
        rs[#rs + 1] = { getPerk = function() return s[1] end, getLevel = function() return s[2] end }
    end
    return {
        getName = function() return name end,
        getTranslationName = function() return display end,
        needToBeLearn = function() return learn or false end,
        getRequiredSkillCount = function() return #rs end,
        getRequiredSkill = function(_, i) return rs[i + 1] end,
        getInputs = function() return list(inputs) end,
    }
end
local R = {
    plank   = recipe("SawPlank", "Saw Planks", { input({ "Base.Log" }), input({ "Base.Saw", "Base.GardenSaw" }) }, false, { { CARP, 1 } }),
    stool   = recipe("MakeStool", "Make Stool", { input({ "Base.Plank" }), input({ "Base.Nails" }), input({ "Base.Saw" }) }, true, { { CARP, 3 } }),
    table_  = recipe("MakeTable", "Make Table", { input({ "Base.Plank" }), input({ "Base.Saw" }) }, false, { { CARP, 3 } }),
    auto    = recipe("FactoryOnly", "Factory Only", { input({ "Base.Saw" }, true) }, false, nil),
    stew    = recipe("MakeStew", "Make Stew", { input({ "Base.Pot" }), input({ "Base.Carrots" }) }, false, { { COOK, 2 } }),
    wall    = recipe("BuildWall", "Wooden Wall", { input({ "Base.Plank" }), input({ "Base.Saw" }) }, false, { { CARP, 4 } }),
}
local CRAFT = { R.plank, R.stool, R.table_, R.auto, R.stew }
local BUILD = { R.wall, R.table_ }   -- (MakeTable in both lists: indexed once)
ScriptManager = { instance = {
    getAllCraftRecipes = function() return list(CRAFT) end,
    getAllBuildableRecipes = function() return list(BUILD) end,
} }

-- the character: Woodwork 3, knows no learned recipe yet
local LEVEL = { Woodwork = 3, Cooking = 0 }
local KNOWN = {}
local player = {
    getPerkLevel = function(_, pk) return LEVEL[pk:getId()] or 0 end,
    isRecipeKnown = function(_, r) return KNOWN[r:getName()] or false end,
}

local OPENED = {}
ISEntityUI = {
    OpenHandcraftWindow = function(p, iso, q, ign, rec, itemString) OPENED[#OPENED + 1] = { "craft", rec and rec:getName(), itemString } end,
    OpenBuildWindow = function(p, iso, q, ign, rec, itemString) OPENED[#OPENED + 1] = { "build", rec and rec:getName(), itemString } end,
}

dofile(ROOT .. "42/media/lua/client/ZeD/RecipeIndex.lua")
local RI = ZeD.RecipeIndex

section("The recipes an item goes into")
local function names(l)
    local out = {}
    for _, r in ipairs(l) do out[#out + 1] = (r.rec or r).name end
    return table.concat(out, ",")
end
local saw = RI.usedIn("Base.Saw")
check("a saw goes into the plank, stool, table and wall (not the automation-only one)", #saw == 4, names(saw))
check("the index was built once", RI.builds == 1, RI.builds)
local garden = RI.usedIn("Base.GardenSaw")
check("an input's other items count (garden saw)", #garden == 1 and garden[1].name == "SawPlank", names(garden))
check("an item no recipe takes: none", #RI.usedIn("Base.Rock") == 0)
local tbl = 0
for _, r in ipairs(RI.usedIn("Base.Plank")) do if r.name == "MakeTable" then tbl = tbl + 1 end end
check("a recipe in both lists is indexed once", tbl == 1, tbl)
local wallKind
for _, r in ipairs(RI.usedIn("Base.Plank")) do if r.name == "BuildWall" then wallKind = r.kind end end
check("a build recipe is kept as build", wallKind == "build", wallKind)

section("Known or Unknown, as the Craft tab's card")
local k = RI.known(player, R and RI.usedIn("Base.Nails")[1])
check("a recipe to learn, not learned: Unknown", k == false)
KNOWN.MakeStool = true
k = RI.known(player, RI.usedIn("Base.Nails")[1])
check("learned and skilled: Known", k == true)
local stew = RI.usedIn("Base.Carrots")[1]
check("not skilled enough: Unknown", RI.known(player, stew) == false)
local rows, more = RI.forCard(player, "Base.Saw", 3)
check("the card's rows: the cap", #rows == 3 and more == 1, tostring(#rows) .. "/" .. tostring(more))
check("known first, then by name", rows[1].known and rows[2].known and rows[3].known
    and rows[1].rec.displayName == "Make Stool" and rows[2].rec.displayName == "Make Table" and rows[3].rec.displayName == "Saw Planks",
    names(rows))
local all = RI.forCard(player, "Base.Saw", 10)
check("the unknown one last (the wall needs Woodwork 4)", all[4] and all[4].rec.name == "BuildWall" and all[4].known == false, names(all))

section("A press opens the game's own way in")
RI.open(player, all[1].rec)
RI.open(player, all[4].rec)
RI.openAll(player, "Base.Saw")
check("a craft recipe: the Craft tab, that recipe", OPENED[1] and OPENED[1][1] == "craft" and OPENED[1][2] == "MakeStool")
check("a build recipe: the Build tab, that recipe", OPENED[2] and OPENED[2][1] == "build" and OPENED[2][2] == "BuildWall")
check("the rest: the Craft tab with the item searched", OPENED[3] and OPENED[3][1] == "craft" and OPENED[3][3] == "Base.Saw")

section("Rebuilt when the game's recipes change")
RI.usedIn("Base.Saw")
check("asked again: not rebuilt", RI.builds == 1, RI.builds)
CRAFT[#CRAFT + 1] = recipe("SawLog", "Saw Log", { input({ "Base.Saw" }) }, false, nil)
RI.usedIn("Base.Saw")
check("before the check's interval: not rebuilt yet", RI.builds == 1, RI.builds)
CLOCK = CLOCK + 6000
check("after it: rebuilt with the new recipe", #RI.usedIn("Base.Saw") == 5 and RI.builds == 2, RI.builds)
CLOCK = CLOCK + 6000
RI.usedIn("Base.Saw")
check("no change: not rebuilt", RI.builds == 2, RI.builds)
Events.OnGameStart.fns[1]()
RI.usedIn("Base.Saw")
check("a game starts: rebuilt", RI.builds == 3, RI.builds)

section("The skill card: what each level still to come needs")
local X = EXTRAS.ZeD_RecipeUnlocks
check("registered with the Skills tab's extras", X and X.cardLines ~= nil)
local lines = X.cardLines(player, CARP, { name = "WoodworkName", level = 2, perk = CARP })
local flat = {}
for _, l in ipairs(lines or {}) do flat[#flat + 1] = l.text .. (l.value and ("=" .. l.value) or "") end
local s = table.concat(flat, "|")
check("the head, level 3 with its two recipes named, then level 4", s == "UI_ZeD_Skills_UnlockHead|UI_ZeD_Skills_UnlockLevel:3=2|  Make Stool|  Make Table|UI_ZeD_Skills_UnlockLevel:4=1", s)
lines = X.cardLines(player, CARP, { level = 4, perk = CARP })
check("at level 4: nothing left", lines == nil)
lines = X.cardLines(player, COOK, { level = 0, perk = COOK })
check("Cooking at 0: level 2 named", lines and #lines == 3 and lines[3].text == "  Make Stew")
RI.NEXT_NAMES = 1
lines = X.cardLines(player, CARP, { level = 2, perk = CARP })
check("past the names: the rest's count", lines and lines[4] and lines[4].text == "  UI_ZeD_Skills_UnlockMore:1", lines and lines[4] and lines[4].text)

-- ---------------------------------------------------------------------------
-- THE WATCH'S PARKED SPEED CONTROLS
-- ---------------------------------------------------------------------------
section("The parked speed controls keep the game's focus pause")
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
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
