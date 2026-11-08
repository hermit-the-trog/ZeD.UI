-- ZeD-UI/42/media/lua/client/ZeD/RecipeIndex.lua
-- ============================================================================
-- THE RECIPE INDEX (punch list 109, Nov 7 2026: "what can I make with this" and "what each skill level
-- unlocks"). Read live from the game's own recipe scripts (ScriptManager: getAllCraftRecipes and
-- getAllBuildableRecipes, CraftRecipe:getInputs, InputScript:getPossibleInputItems, the recipe's required
-- skills). Built once, the first time it is asked, and again when the game's recipe count changes (a check
-- at most every few seconds) or a game starts.
--
-- What it shows the character about a recipe is what the Craft tab's card already shows: Known or Unknown
-- (learned, when the recipe has to be learned, and every skill it needs at its level). Nothing the game
-- keeps back: no auto-learn levels, no where-to-find.
--
--   RI.usedIn(fullType)          -> the recipes that take the item as an input (craft first, then build)
--   RI.atLevel(perkId)           -> { [level] = { rec, ... } } the recipes that need that skill at each level
--   RI.known(player, rec)        -> known, learned, hasSkill
--   RI.forCard(player, fullType, max) -> rows for the item card: known first, then by name; and the rest's count
--   RI.open(player, rec)         -> the recipe in the Craft (or Build) tab, the game's own route in
-- ============================================================================

require "ZeD/SkillsTab"

ZeD = ZeD or {}
ZeD.RecipeIndex = ZeD.RecipeIndex or {}
local RI = ZeD.RecipeIndex

local CHECK_MS = 5000

RI._byItem = nil      -- fullType -> { rec, ... }
RI._byPerk = nil      -- perk id -> { [level] = { rec, ... } }
RI._count  = nil      -- the game's recipe count when built
RI._checkAt = 0
RI.builds = 0         -- (the sims count rebuilds)

local function now()
    local ok, t = pcall(getTimestampMs)
    return ok and tonumber(t) or 0
end

local function sm()
    return ScriptManager and ScriptManager.instance
end

local function listOf(getter)
    local m = sm()
    if not m then return nil end
    local ok, l = pcall(function() return m[getter](m) end)
    if ok then return l end
    return nil
end

local function countNow()
    local n = 0
    local c = listOf("getAllCraftRecipes")
    if c then n = n + c:size() end
    local b = listOf("getAllBuildableRecipes")
    if b then n = n + b:size() end
    return n
end

-- a script item's full type (the game's builds name it getFullName; an inventory item getFullType)
local function fullTypeOf(it)
    local ft = nil
    if it.getFullName then pcall(function() ft = it:getFullName() end) end
    if not ft and it.getFullType then pcall(function() ft = it:getFullType() end) end
    return ft and tostring(ft) or nil
end

local function addRecipe(recipe, kind, byItem, byPerk)
    local rec = { recipe = recipe, kind = kind }
    rec.name = tostring(recipe:getName())
    local dn = nil
    pcall(function() dn = recipe:getTranslationName() end)
    rec.displayName = (dn and dn ~= "") and tostring(dn) or rec.name
    rec.needLearn = false
    pcall(function() if recipe:needToBeLearn() then rec.needLearn = true end end)
    rec.skills = {}
    pcall(function()
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local rs = recipe:getRequiredSkill(i)
            local pk = rs:getPerk()
            rec.skills[#rec.skills + 1] = { perk = pk, id = tostring(pk:getId()), level = rs:getLevel() }
        end
    end)
    -- the items it takes (an automation-only input is not the character's to fill)
    local seen = {}
    pcall(function()
        local inputs = recipe:getInputs()
        for i = 0, inputs:size() - 1 do
            local inp = inputs:get(i)
            local auto = false
            pcall(function() auto = inp:isAutomationOnly() end)
            if not auto then
                local okP, possible = pcall(function() return inp:getPossibleInputItems() end)
                if okP and possible then
                    for j = 0, possible:size() - 1 do
                        local it = possible:get(j)
                        local ft = it and fullTypeOf(it)
                        if ft and not seen[ft] then
                            seen[ft] = true
                            local l = byItem[ft]
                            if not l then l = {}; byItem[ft] = l end
                            l[#l + 1] = rec
                        end
                    end
                end
            end
        end
    end)
    for _, s in ipairs(rec.skills) do
        local p = byPerk[s.id]
        if not p then p = {}; byPerk[s.id] = p end
        local lv = tonumber(s.level) or 0
        if lv > 0 then
            p[lv] = p[lv] or {}
            p[lv][#p[lv] + 1] = rec
        end
    end
end

function RI.build()
    local byItem, byPerk = {}, {}
    local n = 0
    local names = {}   -- (a recipe in both lists is indexed once, as craft)
    for _, pair in ipairs({ { "getAllCraftRecipes", "craft" }, { "getAllBuildableRecipes", "build" } }) do
        local l = listOf(pair[1])
        if l then
            n = n + l:size()
            for i = 0, l:size() - 1 do
                local r = l:get(i)
                local nm = nil
                if r then pcall(function() nm = tostring(r:getName()) end) end
                if r and not (nm and names[nm]) then
                    if nm then names[nm] = true end
                    pcall(addRecipe, r, pair[2], byItem, byPerk)
                end
            end
        end
    end
    RI._byItem, RI._byPerk, RI._count = byItem, byPerk, n
    RI._checkAt = now() + CHECK_MS
    RI.builds = RI.builds + 1
end

function RI.reset() RI._byItem, RI._byPerk, RI._count = nil, nil, nil end

-- the index, rebuilt when the game's recipes changed
local function ensure()
    if not RI._byItem then RI.build(); return end
    local t = now()
    if t >= RI._checkAt then
        RI._checkAt = t + CHECK_MS
        if countNow() ~= RI._count then RI.build() end
    end
end

function RI.usedIn(fullType)
    ensure()
    return (fullType and RI._byItem[fullType]) or {}
end

function RI.atLevel(perkId)
    ensure()
    return (perkId and RI._byPerk[perkId]) or {}
end

-- Known as the Craft tab's card says it: learned (when it must be learned) and every skill at its level
function RI.known(player, rec)
    local learned = true
    if rec.needLearn then
        learned = false
        pcall(function() if player:isRecipeKnown(rec.recipe) then learned = true end end)
    end
    local hasSkill = true
    for _, s in ipairs(rec.skills or {}) do
        local lv = 0
        pcall(function() lv = player:getPerkLevel(s.perk) end)
        if (tonumber(lv) or 0) < (tonumber(s.level) or 0) then hasSkill = false; break end
    end
    return learned and hasSkill, learned, hasSkill
end

-- The item card's rows: up to max, known first, then by name; the rest's count
function RI.forCard(player, fullType, max)
    local list = RI.usedIn(fullType)
    local rows = {}
    for _, rec in ipairs(list) do
        local k = false
        if player then k = RI.known(player, rec) end
        rows[#rows + 1] = { rec = rec, known = k and true or false }
    end
    table.sort(rows, function(a, b)
        if a.known ~= b.known then return a.known end
        if a.rec.displayName ~= b.rec.displayName then return a.rec.displayName < b.rec.displayName end
        return a.rec.name < b.rec.name
    end)
    local out = {}
    max = max or #rows
    for i = 1, math.min(max, #rows) do out[i] = rows[i] end
    return out, #rows - #out
end

-- The recipe in the World window's Craft or Build tab, by the game's own way in (Overrides/Stations.lua
-- routes it to ZeD; with ZeD's window off the game's own window opens)
function RI.open(player, rec)
    if not (player and rec and ISEntityUI) then return false end
    local fn = (rec.kind == "build") and ISEntityUI.OpenBuildWindow or ISEntityUI.OpenHandcraftWindow
    if not fn then return false end
    local ok = pcall(fn, player, nil, nil, nil, rec.recipe, nil)
    return ok
end

-- The rest of the item's recipes: the Craft tab with the item's name in its search (the game's
-- "craft with this item" way in)
function RI.openAll(player, fullType)
    if not (player and fullType and ISEntityUI and ISEntityUI.OpenHandcraftWindow) then return false end
    local ok = pcall(ISEntityUI.OpenHandcraftWindow, player, nil, nil, nil, nil, fullType)
    return ok
end

-- ---------------------------------------------------------------------------
-- THE SKILL CARD: the recipes that need each level still to come (the row's hover card, through the
-- Skills tab's extras). The next level's recipes by name, a few; the rest as counts.
-- ---------------------------------------------------------------------------
RI.NEXT_NAMES = 3
function RI.skillLines(player, perk, skill)
    local id = nil
    if perk then pcall(function() id = tostring(perk:getId()) end) end
    if not id then return nil end
    local by = RI.atLevel(id)
    local cur = tonumber(skill and skill.level) or 0
    local lines = {}
    for lv = cur + 1, 10 do
        local l = by[lv]
        if l and #l > 0 then
            if #lines == 0 then lines[1] = { text = ZeD.tr("UI_ZeD_Skills_UnlockHead") } end
            lines[#lines + 1] = { text = ZeD.tr("UI_ZeD_Skills_UnlockLevel", lv), value = tostring(#l) }
            if #lines == 2 then
                -- the next level's recipes by name
                local named = {}
                for _, rec in ipairs(l) do named[#named + 1] = rec end
                table.sort(named, function(a, b) return a.displayName < b.displayName end)
                for i = 1, math.min(RI.NEXT_NAMES, #named) do
                    lines[#lines + 1] = { text = "  " .. named[i].displayName }
                end
                if #named > RI.NEXT_NAMES then
                    lines[#lines + 1] = { text = "  " .. ZeD.tr("UI_ZeD_Skills_UnlockMore", #named - RI.NEXT_NAMES) }
                end
            end
        end
    end
    return (#lines > 0) and lines or nil
end

if ZeD.SkillsTab and ZeD.SkillsTab.addExtras then
    ZeD.SkillsTab.addExtras("ZeD_RecipeUnlocks", { cardLines = RI.skillLines })
end

-- built as a game starts (once, as the Craft tab's catalog), so the first card opened does not wait for it
if Events and Events.OnGameStart then Events.OnGameStart.Add(function() RI.reset(); pcall(RI.build) end) end
