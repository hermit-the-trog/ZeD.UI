-- ZeDUI/tools/qa/craft_rows_perf_sim.lua  (Nov 7 2026, Build): the outside performance review's items 2, 3, 12 and 13
-- (ZeDUI/qa/REVIEW_PERF_20261107.md) with no game running: the cost goes down and nothing else changes.
--   ROWS     the real CraftingTab.lua and BuildingTab.lua gatherData (rows rewritten in place, one perk lookup per skill,
--            the station names cased once, a name index) against the old code's rows, rebuilt here as they were at
--            7f17686e (a new table per recipe, then CC.carryStatus), over 400 random refreshes of one world: skills
--            up and down, recipes learned and forgotten, recipes the game hides and shows (RecipeIndex), a bench
--            bound and let go, the cache dropped, the game's answers and the quick scan's, the picked recipe's
--            detail. Every row, its status, Known state, tags, carried answer and the picked recipe match; so do the
--            Ready / Known / All lists (the real CC.filterAndSort). Call counts per refresh and per second, before
--            and after.
--   LOGIC    the real CC.logicScan against the old one (verbatim below) on a fake HandcraftLogic that answers from the
--            world as it was when its recipes were last set: the same statuses at every scan while the containers,
--            the recipes known, the skills or the square change; a change it cannot see (an item's condition) is
--            caught within LOGIC_FULL_MS; setContainers / setRecipes and getCachedRecipeInfo counts, before and after.
--   TIMERS   CC.due: the same rate at 60, 144 and 240 Hz, forced by nil, timers made together fall out of step;
--            Stations.nearby: about once a second standing still, at once on a new square, as before on force.
--   TEETH    an in-place row that carries an answer from a row not in the last list is caught.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/craft_rows_perf_sim.lua
-- It prints the numbers, FAIL lines and a last line "craft_rows_perf_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]craft_rows_perf_sim%.lua$", "")

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
math.randomseed(1107)

Events = setmetatable({}, { __index = function(t, k)
    local e = { fns = {} }
    e.Add = function(fn) e.fns[#e.fns + 1] = fn end
    e.Remove = noop
    rawset(t, k, e)
    return e
end })
require = function() return nil end
local CLOCK = 100000
getTimestampMs = function() return CLOCK end

-- ---------------------------------------------------------------------------
-- THE WORLD (stubs) and what the game is asked
-- ---------------------------------------------------------------------------
local COUNT = { perk = 0, known = 0, case = 0, visible = 0 }
local counting = true
local function bump(k) if counting then COUNT[k] = COUNT[k] + 1 end end

Perks = { None = "None" }
local PERK_NAMES = { "Carpentry", "Cooking", "Tailoring", "Metalworking", "Electricity", "NoneSkill", "Unknown" }
local PT = { Carpentry = "P_carp", Cooking = "P_cook", Tailoring = "P_tail", Metalworking = "P_metal",
             Electricity = "P_elec", NoneSkill = "None" }          -- (Unknown: no perk type at all)
local LEVELS = { P_carp = 3, P_cook = 1, P_tail = 0, P_metal = 5, P_elec = 2, None = 7 }
local KNOWN, VIS = {}, {}
local SQ1, SQ2 = { "square 1" }, { "square 2" }
local WORLD = { bench = nil, sq = SQ1, knownN = 0 }

local player = {}
function player:getPerkLevel(pt) bump("perk"); return LEVELS[pt] or 0 end
function player:isRecipeKnown(r) bump("known"); return KNOWN[r:getName()] and true or false end
function player:getKnownRecipes() return list({}) end
function player:getCurrentSquare() return WORLD.sq end
function player:getPlayerNum() return 0 end
function player:getModData() return {} end
getSpecificPlayer = function() return player end

local N_CRAFT = 90
local CRAFT = {}
for i = 1, N_CRAFT do
    local name = "R" .. i
    local skill = (i % 4 ~= 0) and PERK_NAMES[(i % #PERK_NAMES) + 1] or nil
    local lvl = i % 6
    local r = {}
    function r:getName() return name end
    function r:getTranslationName() return string.format("Recipe %03d", (i * 37) % 101) end
    function r:getRequiredSkillCount() return skill and 1 or 0 end
    function r:getRequiredSkill() return { getPerk = function() return { getName = function() return skill end } end,
                                           getLevel = function() return lvl end } end
    function r:isAllowBatchCraft() return i % 2 == 0 end
    function r:needToBeLearn() return i % 3 == 0 end
    function r:getIconTexture() return nil end
    r._station = (i % 5 == 0) and { short = "WORKBENCH " .. (i % 2), heat = false }
              or ((i % 10 == 7) and { short = nil, heat = false }) or nil
    CRAFT[i] = r
end
ScriptManager = { instance = { getAllCraftRecipes = function() return list(CRAFT) end } }

local N_BUILD = 40
local BUILDR = {}
for i = 1, N_BUILD do
    local name = "B" .. i
    local skill = (i % 3 ~= 0) and PERK_NAMES[(i % 5) + 1] or nil
    local r = {}
    function r:getName() return name end
    function r:getTranslationName() return string.format("Build %03d", (i * 17) % 53) end
    function r:getCategory() return "cat" .. (i % 4) end
    function r:getRequiredSkillCount() return skill and 1 or 0 end
    function r:getRequiredSkill() return { getPerk = function() return { getName = function() return skill end } end,
                                           getLevel = function() return i % 7 end } end
    function r:getToolRight() return nil end
    function r:getToolLeft() return nil end
    function r:getToolBoth() return nil end
    function r:getIconTexture() return nil end
    BUILDR[i] = r
end
BuildLogic = { new = function() return { getAllBuildableRecipes = function() return list(BUILDR) end } end }

local BENCH = { kind = "bench", key = "bench@1", obj = { "bench obj" } }
local BENCHSET = {}
for i = 1, N_CRAFT do if i % 2 == 0 or i % 5 == 0 then BENCHSET["R" .. i] = true end end

ZeD = {
    tr = function(k) return k end,
    upper = string.upper,
    textCase = function(s) bump("case"); if s == nil then return s end; return string.lower(tostring(s)) end,
    RecipeIndex = { visible = function(p, r) bump("visible"); return VIS[r:getName()] ~= false end },
    Stations = {
        recipeStation = function(r) return r._station end,
        current = function() return WORLD.bench end,
        recipeSet = function() return BENCHSET end,
    },
}

-- CraftingCore: the real pieces under test (cut from the file), the catalog helpers stubbed
local CC = {
    prebakeInputs = function() return {} end, prebakeOutputs = function() return {} end,
    prebakeSkills = function() return {} end,
    resolveCategory = function(r, skill) return skill or "Miscellaneous" end,
    getPerkType = function(n) return PT[n] end,
    getInputName = function() return "?" end,
}
ZeD.CraftingCore = CC
local cut = dofile(ROOT .. "ZeDUI/tools/qa/cc_cut.lua")
cut(ROOT, CC, { "function CC.due(", "function CC.carryStatus(", "function CC.rowsBegin(", "function CC.refreshRow(",
    "function CC.perkLevelOf(", "function CC.rowsEnd(", "function CC.showMode(", "function CC.filterAndSort(",
    "local function logicSig(", "local function sameContainers(", "function CC.logicScan(" })

local okC, errC = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/CraftingTab.lua")
check("CraftingTab.lua loads on the stubs", okC, errC)
local okB, errB = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/BuildingTab.lua")
check("BuildingTab.lua loads on the stubs", okB, errB)
if not (okC and okB) then
    print("craft_rows_perf_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(1)
end
for _, fn in ipairs(Events.OnGameStart.fns) do fn() end

-- ---------------------------------------------------------------------------
-- THE OLD CODE'S ROWS (7f17686e), rebuilt on the same world: a new table per recipe, then carryStatus
-- ---------------------------------------------------------------------------
local function oldCarry(oldData, newData)   -- CC.carryStatus as it was (it is still in the file, unchanged)
    if not (oldData and newData and oldData.recipes and newData.recipes) then return end
    local prev = {}
    for _, rd in ipairs(oldData.recipes) do prev[rd.entry.name] = rd end
    for _, rd in ipairs(newData.recipes) do
        local o = prev[rd.entry.name]
        if o and o.fromLogic and rd.status ~= "locked" and rd.status ~= "station"
           and (o.status == "craftable" or o.status == "missing") then
            rd.status, rd.fromLogic = o.status, true
        end
    end
end

local function oldCraftRows(playerObj, source, bench, prevData)
    local recipes = {}
    local boundShort = nil
    if bench then
        for _, e in ipairs(source) do
            if e.stationInfo then boundShort = e.stationInfo.short; break end
        end
    end
    for _, entry in ipairs(source) do
      if ZeD.RecipeIndex.visible(playerObj, entry.recipe, "craft") then
        local hasSkill, playerLevel = true, 0
        if entry.skillName then
            local perkType = CC.getPerkType(entry.skillName)
            if perkType and perkType ~= Perks.None then playerLevel = playerObj:getPerkLevel(perkType) end
            hasSkill = playerLevel >= entry.requiredLevel
        end
        local learned = true
        if entry.needLearn then
            learned = false
            pcall(function() if playerObj:isRecipeKnown(entry.recipe) then learned = true end end)
        end
        local status = (not learned or not hasSkill) and "locked" or "unlocked"
        local needs = (not bench) and entry.stationInfo or nil
        if needs and status == "unlocked" then status = "station" end
        recipes[#recipes + 1] = {
            stationNeed = needs,
            stationTag  = needs and ZeD.textCase(needs.short) or nil,
            boundShort  = bench and ZeD.textCase(entry.stationInfo and entry.stationInfo.short or boundShort) or nil,
            entry = entry, status = status, hasSkill = hasSkill, learned = learned, playerLevel = playerLevel,
            ingredients = nil, missingCount = 0,
        }
      end
    end
    local data = { recipes = recipes, flatRecipes = source }
    oldCarry(prevData, data)
    return data
end

local function oldBuildRows(playerObj, source, prevData)
    local recipes = {}
    for _, entry in ipairs(source) do
        local hasSkill, playerLevel = true, 0
        if entry.skillName then
            local perkType = CC.getPerkType(entry.skillName)
            if perkType and perkType ~= Perks.None then playerLevel = playerObj:getPerkLevel(perkType) end
            hasSkill = playerLevel >= entry.requiredLevel
        end
        recipes[#recipes + 1] = { entry = entry, status = hasSkill and "unlocked" or "locked", hasSkill = hasSkill,
            learned = true, playerLevel = playerLevel, ingredients = nil, missingCount = 0 }
    end
    local data = { recipes = recipes, flatRecipes = source }
    oldCarry(prevData, data)
    return data
end

-- ---------------------------------------------------------------------------
-- What happens to rows between refreshes, done the same way to both lists
-- ---------------------------------------------------------------------------
local ANSWER = {}      -- the game's answer per recipe name: "craftable" / "missing" / "invalid"
local QUICK = {}       -- the quick scan's answer per recipe name
local function gameAnswers(rows)          -- as CC.logicScan's loop sets them
    for _, rd in ipairs(rows) do
        if rd.status ~= "station" then
            local a = ANSWER[rd.entry.name]
            local st = (a == "invalid") and "locked" or a
            if rd.learned == false or rd.hasSkill == false then st = "locked" end
            rd.fromLogic = true
            rd.status = st
        end
    end
end
local function gameFails(rows) for _, rd in ipairs(rows) do rd.fromLogic = nil end end
local function quickScan(rows)            -- as CC.backgroundIngredientScan / quickCraftCheck set them
    for _, rd in ipairs(rows) do
        if rd.status ~= "locked" and not rd.fromLogic and rd.status ~= "station" then rd.status = QUICK[rd.entry.name] end
    end
end
local function detail(rows, sel)          -- the picked recipe's detail gather writes onto its row
    for _, rd in ipairs(rows) do
        if rd.entry.name == sel then
            rd.ingredients, rd.missingCount, rd.skills, rd.craftTime = { "x" }, 2, { "y" }, 30
            rd.canStart, rd.maxBatchQty = true, 3
            return
        end
    end
end
local function linearFind(rows, sel)
    for i, rd in ipairs(rows) do if rd.entry.name == sel then return rd, i end end
    return nil, nil
end

local FIELDS = { "status", "hasSkill", "learned", "playerLevel", "stationTag", "boundShort", "fromLogic",
                 "ingredients", "missingCount", "skills", "craftTime", "canStart", "maxBatchQty" }
local function sameRows(a, b)
    if #a.recipes ~= #b.recipes then return false, "rows " .. #a.recipes .. " vs " .. #b.recipes end
    for i = 1, #a.recipes do
        local x, y = a.recipes[i], b.recipes[i]
        if x.entry ~= y.entry then return false, "row " .. i .. ": " .. x.entry.name .. " vs " .. y.entry.name end
        if x.stationNeed ~= y.stationNeed then return false, "row " .. i .. " stationNeed" end
        for _, f in ipairs(FIELDS) do
            local u, v = x[f], y[f]
            if type(u) == "table" and type(v) == "table" then u, v = #u, #v end
            if u ~= v then return false, x.entry.name .. "." .. f .. ": " .. tostring(u) .. " vs " .. tostring(v) end
        end
    end
    return true
end
local function namesOf(rows)
    local t = {}
    for i, rd in ipairs(rows) do t[i] = rd.entry.name end
    return table.concat(t, ",")
end

local function randomize(kind)
    -- skills, known recipes, hidden recipes, answers
    for _, pt in pairs(PT) do if math.random() < 0.15 then LEVELS[pt] = math.random(0, 6) end end
    for i = 1, N_CRAFT do
        local nm = "R" .. i
        if math.random() < 0.08 then KNOWN[nm] = not KNOWN[nm] end
        if kind ~= "build" and math.random() < 0.05 then VIS[nm] = (VIS[nm] == false) and true or false end
    end
    for i = 1, math.max(N_CRAFT, N_BUILD) do
        for _, nm in ipairs({ "R" .. i, "B" .. i }) do
            if ANSWER[nm] == nil or math.random() < 0.2 then
                local u = math.random()
                ANSWER[nm] = (u < 0.4 and "craftable") or (u < 0.8 and "missing") or "invalid"
            end
            if QUICK[nm] == nil or math.random() < 0.2 then QUICK[nm] = (math.random() < 0.5) and "craftable" or "missing" end
        end
    end
end

-- ---------------------------------------------------------------------------
section("ROWS: the Craft tab, rows in place against the old rows")
-- ---------------------------------------------------------------------------
local function runRows(kind, steps)
    local win = { _playerObj = player }
    local refPrev, sel = nil, nil
    local mismatch, selMismatch, modeMismatch = nil, nil, nil
    local reused, refreshes = 0, 0
    local gather = (kind == "craft") and ZeD.CraftingTab.gatherData or ZeD.BuildingTab.gatherData
    for step = 1, steps do
        randomize(kind)
        if kind == "craft" and math.random() < 0.08 then
            local nb = (WORLD.bench == nil) and BENCH or nil
            WORLD.bench = nb
            refPrev = nil   -- (the old tab dropped its cache on a new source too: nothing carried)
        end
        if math.random() < 0.05 then   -- a craft, a search, a station change: the cache dropped (both)
            if kind == "craft" then win._craftCache = nil else win._buildCache = nil end
            refPrev = nil
        end
        CLOCK = CLOCK + 1001
        local cache0 = (kind == "craft") and win._craftCache or win._buildCache
        local data = gather(player, win)
        refreshes = refreshes + 1
        if data == cache0 then reused = reused + 1 end
        counting = false
        local ref = (kind == "craft") and oldCraftRows(player, data.flatRecipes, WORLD.bench, refPrev)
                                      or oldBuildRows(player, data.flatRecipes, refPrev)
        counting = true
        local ok, why = sameRows(data, ref)
        if not ok and not mismatch then mismatch = "step " .. step .. ": " .. why end
        -- the picked recipe (sometimes one the list does not hold)
        if math.random() < 0.3 then sel = ((kind == "craft") and "R" or "B") .. math.random(1, (kind == "craft") and N_CRAFT or N_BUILD) end
        if sel then
            local a = data.byName[sel]
            local b, bi = linearFind(ref.recipes, sel)
            local _, ai = linearFind(data.recipes, sel)
            if (a == nil) ~= (b == nil) or (a and (a.entry ~= b.entry or a ~= data.recipes[ai] or ai ~= bi)) then
                selMismatch = selMismatch or ("step " .. step .. ": " .. sel)
            end
        end
        -- Ready / Known / All lists from both
        for _, show in ipairs({ "ready", "known", "all" }) do
            local st = { show = show, sort = (show == "known") and "known" or "craftable", search = "", pins = {} }
            local fa = CC.filterAndSort(data, st, {})
            local fb = CC.filterAndSort(ref, st, {})
            if namesOf(fa) ~= namesOf(fb) then modeMismatch = modeMismatch or ("step " .. step .. " " .. show) end
        end
        -- between refreshes: the game's answers (or a failed scan), the quick scan, the picked recipe's detail
        local u = math.random()
        if u < 0.6 then gameAnswers(data.recipes); gameAnswers(ref.recipes)
        elseif u < 0.68 then gameFails(data.recipes); gameFails(ref.recipes) end
        if math.random() < 0.3 then quickScan(data.recipes); quickScan(ref.recipes) end
        if sel then detail(data.recipes, sel); detail(ref.recipes, sel) end
        refPrev = ref
    end
    return mismatch, selMismatch, modeMismatch, reused, refreshes
end

local m1, s1, f1, reused = runRows("craft", 400)
check("Craft: every row as the old code made it, 400 refreshes", m1 == nil, m1)
check("Craft: the picked recipe found as the linear search found it", s1 == nil, s1)
check("Craft: Ready / Known / All list the same recipes in the same order", f1 == nil, f1)
check("Craft: one data table kept while the cache stands", reused > 300, reused)

section("ROWS: the Build tab")
local m2, s2, f2 = runRows("build", 300)
check("Build: every row as the old code made it, 300 refreshes", m2 == nil, m2)
check("Build: the picked recipe found as before", s2 == nil, s2)
check("Build: Ready / Known / All the same", f2 == nil, f2)

-- the cost of one Craft refresh, before and after
do
    for k in pairs(COUNT) do COUNT[k] = 0 end
    WORLD.bench = nil
    for i = 1, N_CRAFT do VIS["R" .. i] = true end
    local win = { _playerObj = player }
    ZeD.CraftingTab.gatherData(player, win)          -- (the first fills the pool)
    for k in pairs(COUNT) do COUNT[k] = 0 end
    CLOCK = CLOCK + 1001
    local data = ZeD.CraftingTab.gatherData(player, win)
    local after = { perk = COUNT.perk, known = COUNT.known, case = COUNT.case }
    for k in pairs(COUNT) do COUNT[k] = 0 end
    oldCraftRows(player, data.flatRecipes, nil, data)
    local before = { perk = COUNT.perk, known = COUNT.known, case = COUNT.case }
    local rows = #data.recipes
    print(string.format("   one Craft refresh, %d rows: getPerkLevel %d -> %d, isRecipeKnown %d -> %d (closures %d -> 0), textCase %d -> %d, row tables %d -> 0",
        rows, before.perk, after.perk, before.known, after.known, before.known, before.case, after.case, rows))
    check("Craft refresh: getPerkLevel once per skill, not per recipe", after.perk <= 6 and before.perk > after.perk * 5, after.perk)
    check("Craft refresh: isRecipeKnown asked as often as before (only the closure goes)", after.known == before.known)
    check("Craft refresh: the station names cased once, not every refresh", after.case == 0 and before.case > 0, after.case)
    -- refreshes per second at 144 Hz: 30 frames before, ROWS_MS after
    local oldN, newN, t = 0, 0, 0
    local frame = 0
    CLOCK = CLOCK + 5000
    local w2 = { _playerObj = player }
    local c0 = nil
    for f = 1, 1440 do               -- 10 s at 144 Hz
        frame = frame + 1
        if frame >= 30 then frame = 0; oldN = oldN + 1 end
        CLOCK = CLOCK + 1000 / 144
        local d = ZeD.CraftingTab.gatherData(player, w2)
        if d.gen ~= c0 then newN = newN + 1; c0 = d.gen end
    end
    print(string.format("   10 s at 144 Hz: Craft refreshes %d -> %d", oldN, newN))
    check("10 s at 144 Hz: about one refresh a second", newN >= 10 and newN <= 12, newN)
end

-- ---------------------------------------------------------------------------
section("LOGIC: CC.logicScan against the old scan")
-- ---------------------------------------------------------------------------
-- the old CC.logicScan, verbatim from 7f17686e
local OLD_LOGIC_EVERY_MS = 1200
local function oldLogicScan(data, win, prefix, makeLogic)
    local recipes = data and data.recipes
    if not recipes or #recipes == 0 or not makeLogic then return false end
    local now = getTimestampMs()
    local atKey = "_" .. prefix .. "LogicAt"
    if win[atKey] and now - win[atKey] < OLD_LOGIC_EVERY_MS then return false end
    win[atKey] = now
    local lKey, dKey = "_" .. prefix .. "Logic", "_" .. prefix .. "LogicData"
    local logic = win[lKey]
    if not logic then
        local ok, l = pcall(makeLogic)
        if not ok or not l then
            for _, rd in ipairs(recipes) do rd.fromLogic = nil end
            return false
        end
        logic = l
        win[lKey], win[dKey] = logic, nil
    end
    local ok = pcall(function()
        local containers = CC.buildContainers(win._playerObj)
        win["_" .. prefix .. "Containers"] = containers
        win["_" .. prefix .. "TypeCache"] = nil
        logic:setContainers(containers)
        local lk = "_" .. prefix .. "LogicList"
        if win[dKey] ~= data or not win[lk] then
            local list = ArrayList.new()
            for _, rd in ipairs(recipes) do if rd.entry.recipe then list:add(rd.entry.recipe) end end
            win[lk] = list
            win[dKey] = data
        end
        logic:setRecipes(win[lk])
    end)
    if not ok then
        win[lKey] = nil
        for _, rd in ipairs(recipes) do rd.fromLogic = nil end
        return false
    end
    local changed = false
    for _, rd in ipairs(recipes) do
        local r = rd.entry.recipe
        if r and rd.status ~= "station" then
            local info = nil
            pcall(function() info = logic:getCachedRecipeInfo(r) end)
            if info then
                local st
                if not info:isValid() then st = "locked"
                elseif info:isCanPerform() then st = "craftable"
                else st = "missing" end
                if (rd.learned == false or rd.hasSkill == false) then st = "locked" end
                rd.fromLogic = true
                if st ~= rd.status then rd.status = st; changed = true end
            end
        end
    end
    return changed
end

ArrayList = { new = function()
    local t = {}
    return { add = function(_, x) t[#t + 1] = x end, size = function() return #t end, get = function(_, i) return t[i + 1] end }
end }
-- the world the fake logic reads: two containers, items, a hidden condition it does not report in the signature
local BAG = { n = 4, w = 2.5 }
local MAIN = { n = 10, w = 7.0 }
local HIDDEN = { cond = 1 }
local KNOWN_N = { n = 3 }
local function container(st)
    local c = {}
    function c:getItems() return { size = function() return st.n end } end
    function c:getContentsWeight() return st.w end
    return c
end
local MAINC, BAGC = container(MAIN), container(BAG)
CC.buildContainers = function() local l = ArrayList.new(); l:add(MAINC); l:add(BAGC); return l end
PerkFactory = { PerkList = list({ "P_carp", "P_cook", "P_tail", "P_metal", "P_elec" }) }
function player:getKnownRecipes() return { size = function() return KNOWN_N.n end } end

local LC = { setC = 0, setR = 0, info = 0 }
local function worldAnswer(name)   -- what the game would answer now, from everything
    local h = 0
    for i = 1, #name do h = h + string.byte(name, i) end
    h = h + MAIN.n * 3 + BAG.n * 5 + math.floor(MAIN.w + BAG.w) + KNOWN_N.n * 7 + (LEVELS.P_carp or 0) * 11
        + HIDDEN.cond * 13 + ((WORLD.sq == SQ2) and 17 or 0)
    local k = h % 3
    return (k == 0 and "craftable") or (k == 1 and "missing") or "invalid"
end
local function fakeLogic()
    local cache = {}
    local l = {}
    function l:setContainers() LC.setC = LC.setC + 1 end
    function l:setRecipes(rl)
        LC.setR = LC.setR + 1
        cache = {}
        for i = 0, rl:size() - 1 do local r = rl:get(i); cache[r] = worldAnswer(r:getName()) end
    end
    function l:getCachedRecipeInfo(r)
        LC.info = LC.info + 1
        local a = cache[r]
        if not a then return nil end
        return { isValid = function() return a ~= "invalid" end, isCanPerform = function() return a == "craftable" end }
    end
    return l
end

do
    for i = 1, N_CRAFT do VIS["R" .. i] = true; KNOWN["R" .. i] = true end
    for _, pt in pairs(PT) do LEVELS[pt] = 6 end
    WORLD.bench, WORLD.sq = nil, SQ1
    local winN, winO = { _playerObj = player }, { _playerObj = player }
    CLOCK = CLOCK + 10000
    local dN = ZeD.CraftingTab.gatherData(player, winN)
    -- the old scan gets its own rows, made the old way, a new data table every refresh as the old tab made
    local dO = oldCraftRows(player, dN.flatRecipes, nil, nil)
    local newSets, oldSets, newInfo, oldInfo = 0, 0, 0, 0
    local diffAt, lagMax, lagStart = nil, 0, nil
    local scansCompared = 0
    local frames = 60 * 144   -- 60 s at 144 Hz
    for f = 1, frames do
        CLOCK = CLOCK + 1000 / 144
        local t = f / 144
        -- what changes: an item picked up, a recipe learned, a level, a step, an item's condition (hidden)
        if f == 10 * 144 then MAIN.n = MAIN.n + 1; MAIN.w = MAIN.w + 0.4 end
        if f == 20 * 144 then KNOWN_N.n = KNOWN_N.n + 1 end
        if f == 30 * 144 then LEVELS.P_carp = 7 end
        if f == 40 * 144 then HIDDEN.cond = 2; lagStart = CLOCK end
        if f == 50 * 144 then WORLD.sq = SQ2 end
        if f == 52 * 144 then BAG.w = BAG.w + 1.0 end
        dN = ZeD.CraftingTab.gatherData(player, winN)
        if f % 30 == 0 then dO = oldCraftRows(player, dN.flatRecipes, nil, dO) end
        local s0, r0, i0 = LC.setC, LC.setR, LC.info
        CC.logicScan(dN, winN, "craft", fakeLogic)
        newSets, newInfo = newSets + (LC.setR - r0), newInfo + (LC.info - i0)
        s0, r0, i0 = LC.setC, LC.setR, LC.info
        oldLogicScan(dO, winO, "craft", fakeLogic)
        oldSets, oldInfo = oldSets + (LC.setR - r0), oldInfo + (LC.info - i0)
        -- compare the statuses by name on the frames both scans ran (between scans the rows refresh on
        -- their own clocks, 30 frames before and ROWS_MS now, and either may show its base status)
        if winN._craftLogicAt == CLOCK and winO._craftLogicAt == CLOCK then
        local byO = {}
        for _, rd in ipairs(dO.recipes) do byO[rd.entry.name] = rd.status end
        local same = true
        for _, rd in ipairs(dN.recipes) do if byO[rd.entry.name] ~= rd.status then same = false; break end end
        if lagStart and same then
            lagMax = math.max(lagMax, CLOCK - lagStart); lagStart = nil
        end
        if not same and not lagStart and not diffAt then diffAt = string.format("%.2f s", t) end
        scansCompared = scansCompared + 1
        end
    end
    print(string.format("   60 s of Craft at 144 Hz: setContainers / setRecipes %d -> %d, getCachedRecipeInfo %d -> %d (closures %d -> 0)",
        oldSets, newSets, oldInfo, newInfo, oldInfo))
    check("the same answers as the old scan at every scan (what the signature sees)", diffAt == nil and scansCompared >= 45, diffAt or scansCompared)
    check("a change it cannot see is caught within LOGIC_FULL_MS", lagStart == nil and lagMax <= 6000 + 1200, lagMax)
    print(string.format("   the hidden change caught after %.1f s", lagMax / 1000))
    check("setRecipes far fewer than the old scan's", newSets * 3 <= oldSets, newSets .. " vs " .. oldSets)
    check("getCachedRecipeInfo as often as before (no closure per recipe)", newInfo == oldInfo, newInfo .. " vs " .. oldInfo)

    -- a new bench or a list whose recipes change asks the game afresh at once
    local r0 = LC.setR
    winN._craftLogic = nil; winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    check("a new logic (a new bench): its recipes set at once", LC.setR == r0 + 1)
    r0 = LC.setR
    VIS.R1 = false; winN._craftCache = nil
    dN = ZeD.CraftingTab.gatherData(player, winN)
    winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    check("a list that changed: made again and set at once", LC.setR == r0 + 1)
    r0 = LC.setR
    winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    check("nothing changed: not set again", LC.setR == r0)
    -- a signature that cannot be read: set every scan, as before
    local saved = player.getKnownRecipes
    player.getKnownRecipes = function() error("no") end
    r0 = LC.setR
    winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    check("no signature: set every scan, as before", LC.setR == r0 + 2)
    player.getKnownRecipes = saved
    -- another bag of the same items and weight in place of the first: set again (compared as objects)
    local realBuild = CC.buildContainers
    local OTHER = container(BAG)
    CC.buildContainers = function() local l = ArrayList.new(); l:add(MAINC); l:add(OTHER); return l end
    r0 = LC.setR
    winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    check("another bag, the same counts and weight: set again", LC.setR == r0 + 1)
    CC.buildContainers = realBuild
    winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    -- the containers and the quick scan's cache still follow every scan (the Craft button's start check keys on them)
    local c1 = winN._craftContainers
    winN._craftLogicAt = nil; winN._craftTypeCache = {}
    CC.logicScan(dN, winN, "craft", fakeLogic)
    check("each scan gathers the containers again and drops the type cache", winN._craftContainers ~= c1 and winN._craftTypeCache == nil)

    -- what the game's answer should say for a row now
    local function expect(rd)
        local a = worldAnswer(rd.entry.name)
        local st = (a == "invalid") and "locked" or a
        if rd.learned == false or rd.hasSkill == false then st = "locked" end
        return st
    end
    local function rowOf(d, nm) return d.byName[nm] end

    -- a refused craft, for a reason the signature cannot see (an item's condition): the next scan, on the
    -- frame after the press, sets the recipes in full and the row shows the game's new answer
    local queued = 0
    ISTimedActionQueue = { add = function() queued = queued + 1 end }
    HandcraftLogic = { new = function()
        return { setContainers = noop, setRecipe = noop, canPerformCurrentRecipe = function() return false end,
                 isCharacterInRangeOfWorkbench = function() return true end, getPossibleCraftCount = function() return 0 end }
    end }
    ZeD.Stations.validate = function() return nil end
    winN._craftLogicAt, winN._craftLogicFullAt = nil, nil
    CC.logicScan(dN, winN, "craft", fakeLogic)                -- (a full set, the answers as they are)
    local rd2 = rowOf(dN, "R2")
    check("the row starts on the game's answer", rd2 and rd2.status == expect(rd2), rd2 and rd2.status)
    HIDDEN.cond = HIDDEN.cond + 1                              -- (the signature reads the same)
    CLOCK = CLOCK + 1300
    winN._craftLogicAt = nil
    CC.logicScan(dN, winN, "craft", fakeLogic)
    check("unseen change, no press: the row keeps the old answer (the saving)", rd2.status ~= expect(rd2), rd2.status)
    CLOCK = CLOCK + 100
    local st = { selected = "R2", qty = 1 }
    ZeD.CraftingTab.startCraft(winN, st)
    check("the press is refused: nothing queued", queued == 0)
    CLOCK = CLOCK + 16
    local r0 = LC.setR
    CC.logicScan(dN, winN, "craft", fakeLogic)                -- (the next frame's scan)
    check("the refused press: the next frame's scan sets the recipes in full", LC.setR == r0 + 1)
    check("the refused press: the row shows the game's new answer on that frame", rd2.status == expect(rd2), rd2.status)

    -- at a bench: every scan sets the recipes in full, so a bench's own change (a forge reaching heat)
    -- shows within one scan; in Hand mode the same change waits for the full refresh
    local winB, winH = { _playerObj = player }, { _playerObj = player }
    local dB = dN
    CC.logicScan(dB, winB, "craft", fakeLogic, true)
    CC.logicScan(dB, winH, "craft", fakeLogic, false)
    CLOCK = CLOCK + 1200
    CC.logicScan(dB, winB, "craft", fakeLogic, true)
    CC.logicScan(dB, winH, "craft", fakeLogic, false)
    local rB = LC.setR
    HIDDEN.cond = HIDDEN.cond + 1                              -- (the bench reaches heat: unseen by the signature)
    CLOCK = CLOCK + 1200
    CC.logicScan(dB, winB, "craft", fakeLogic, true)
    check("at a bench: the change shows within 1.2 s", LC.setR == rB + 1 and rd2.status == expect(rd2), rd2.status)
    local rH = LC.setR
    CC.logicScan(dB, winH, "craft", fakeLogic, false)
    check("in Hand mode: no full set on an unseen change before LOGIC_FULL_MS (the saving kept)", LC.setR == rH)
    local tc = 0
    for i = 1, 5 do
        CLOCK = CLOCK + 1200
        r0 = LC.setR
        CC.logicScan(dB, winB, "craft", fakeLogic, true)
        if LC.setR == r0 + 1 then tc = tc + 1 end
    end
    check("at a bench: the full set every scan", tc == 5, tc)
end

-- ---------------------------------------------------------------------------
section("TIMERS: CC.due and Stations.nearby")
-- ---------------------------------------------------------------------------
do
    local function fires(hz, ms, secs)
        local w, n = {}, 0
        for f = 1, hz * secs do
            CLOCK = CLOCK + 1000 / hz
            if CC.due(w, "_k", ms) then n = n + 1 end
        end
        return n
    end
    local a, b, c = fires(60, 500, 10), fires(144, 500, 10), fires(240, 500, 10)
    print(string.format("   a 500 ms timer over 10 s: %d at 60 Hz, %d at 144 Hz, %d at 240 Hz (30 frames: 20, 48, 80)", a, b, c))
    check("the same rate at 60, 144 and 240 Hz", math.abs(a - b) <= 1 and math.abs(b - c) <= 1 and a >= 20 and a <= 21, a .. "/" .. b .. "/" .. c)
    local w = {}
    check("the first call fires", CC.due(w, "_x", 1000) == true)
    check("not again at once", CC.due(w, "_x", 1000) == false)
    check("forced: fires", CC.due(w, "_x", 1000, true) == true)
    w._x = nil
    check("nil: fires", CC.due(w, "_x", 1000) == true)
    local w1, w2, w3 = {}, {}, {}
    CC.due(w1, "_t", 1000); CC.due(w2, "_t", 1000); CC.due(w3, "_t", 1000)
    check("timers made together fall out of step", w1._t ~= w2._t and w2._t ~= w3._t and w1._t ~= w3._t)
    check("the first wait is never under half the interval", w1._t - CLOCK >= 500 and w2._t - CLOCK >= 500 and w3._t - CLOCK >= 500)
end

do
    ZeD.Stations = {}
    getCell = function() return nil end
    local okS, errS = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/Stations.lua")
    check("Stations.lua loads", okS, errS)
    local ST = ZeD.Stations
    local scans = 0
    ST.scan = function() scans = scans + 1; return { { key = "k" .. scans, kind = "bench" } } end
    WORLD.sq = SQ1
    CLOCK = CLOCK + 5000
    local oldN, t = 0, 31   -- the old count: a rescan when 30 calls had passed
    for f = 1, 1440 do      -- 10 s at 144 Hz, a station view drawing every frame
        CLOCK = CLOCK + 1000 / 144
        ST.nearby(player)
        if t >= 30 then oldN = oldN + 1; t = 0 else t = t + 1 end
    end
    print(string.format("   10 s at 144 Hz, standing still: Stations scans %d -> %d", oldN, scans))
    check("standing still: about once a second", scans >= 10 and scans <= 11, scans)
    local s0 = scans
    ST.nearby(player)
    check("the same square, within the second: no scan", scans == s0)
    ST.nearby(player, true)
    check("forced: scanned", scans == s0 + 1)
    s0 = scans
    CLOCK = CLOCK + 100
    WORLD.sq = SQ2
    ST.nearby(player)
    check("a new square 100 ms after a scan: not yet", scans == s0)
    CLOCK = CLOCK + 160
    ST.nearby(player)
    check("a new square, 250 ms on: scanned", scans == s0 + 1)
    -- a sprint: a new square every 1/7 s for 5 s, the view drawing at 144 Hz
    local sqs = {}
    for i = 1, 40 do sqs[i] = { "sprint square " .. i } end
    s0 = scans
    local nextSq, si = CLOCK, 0
    for f = 1, 5 * 144 do
        CLOCK = CLOCK + 1000 / 144
        if CLOCK >= nextSq then si = si + 1; WORLD.sq = sqs[si] or WORLD.sq; nextSq = nextSq + 1000 / 7 end
        ST.nearby(player)
    end
    local perSec = (scans - s0) / 5
    print(string.format("   a sprint, a new square 7 times a second: %.1f scans a second (no gap: 7)", perSec))
    check("a sprint: at most 4 rescans a second", perSec <= 4, perSec)
    check("a sprint: still rescans as it goes", perSec >= 2, perSec)
    WORLD.sq = SQ1
end

-- ---------------------------------------------------------------------------
section("TEETH: a row carrying an answer from outside the last list is caught")
-- ---------------------------------------------------------------------------
do
    local real = CC.refreshRow
    CC.refreshRow = function(pool, entry, gen, prevGen, ...)
        return real(pool, entry, gen, (pool[entry] and pool[entry]._gen) or prevGen, ...)   -- (ignores the last list)
    end
    local m = runRows("craft", 400)
    check("the broken carry is caught", m ~= nil)
    -- a row that keeps the picked recipe's detail across a refresh (a new row had none)
    CC.refreshRow = function(pool, entry, ...)
        local rd = pool[entry]
        local keep = rd and rd.ingredients
        rd = real(pool, entry, ...)
        rd.ingredients = keep
        return rd
    end
    local m2 = runRows("craft", 400)
    check("a row keeping the old detail is caught", m2 ~= nil)
    CC.refreshRow = real
end

print("craft_rows_perf_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
