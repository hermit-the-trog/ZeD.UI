-- ZeD-UI/42/media/lua/client/ZeD/RecipeIndex.lua
-- ============================================================================
-- THE RECIPES THE GAME SHOWS: client; the data behind "what can I make with this" and "what each skill
-- level unlocks". Read live from the game, and only what the game itself would list for the character:
--   * a recipe that must be learned, not learned, with the world's "See Not Known Recipes" (SeeNotLearntRecipe)
--     off, is not shown (the game's own rule: Item.getUsedInRecipes(character) on 42.21);
--   * a recipe whose OnAddToMenu check fails is not shown, as the game's crafting window drops it (its list
--     asks with shouldShowAll = true; the debug piano is one).
-- The item card reads the game's own list for the item (its script item's getUsedInRecipes(character)). The
-- skill card reads an index of the levels the recipes need (and, with ZeD setup's "Recipes skills teach" on,
-- the levels the game teaches them at by itself: Vanilla Access on, Vanilla and Vanilla Plus off as the game,
-- Custom the player's pick), built once and again when the game's recipe count
-- changes (a check at most every few seconds) or a game starts. The Craft and Journal tabs ask RI.visible too.
--
-- Known or Unknown is what the Craft tab's card says: learned (when it must be learned) and every skill at its
-- level. The answers are kept until the character's known recipes or a skill level change (RI.gen).
--
--   RI.visible(player, recipe)          -> false for a recipe the game would not list for the character
--   RI.usedInFor(player, scriptItem)    -> the recipes the item goes into, as the game lists them
--   RI.forCard(player, scriptItem, max) -> the item card's rows: known first, then by name; and the rest's count
--   RI.atLevel(perkId) / RI.taughtAt(perkId) -> { [level] = { rec, ... } } (every recipe; the card filters)
--   RI.known(player, rec)               -> known, learned, hasSkill
--   RI.open(player, rec) / RI.openAll(player, fullType) -> the Craft (or Build) tab, the game's own way in
-- ============================================================================

require "ZeD/SkillsTab"

ZeD = ZeD or {}
ZeD.RecipeIndex = ZeD.RecipeIndex or {}
local RI = ZeD.RecipeIndex

local CHECK_MS = 5000

RI._byPerk = nil      -- perk id -> { [level] = { rec, ... } }
RI._byAuto = nil      -- perk id -> { [level] = { rec, ... } } (auto-learn)
RI._count  = nil      -- the game's recipe count when built
RI._checkAt = 0
RI.builds = 0         -- (the sims count rebuilds)
RI._recs = RI._recs or {}   -- kind .. ":" .. name -> rec (what never changes about a recipe)
RI._perkGen = RI._perkGen or 0

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

-- ---------------------------------------------------------------------------
-- A RECIPE'S FIXED FACTS, read once
-- ---------------------------------------------------------------------------
function RI.rec(recipe, kind)
    if not recipe then return nil end
    local name = nil
    pcall(function() name = tostring(recipe:getName()) end)
    if not name then return nil end
    local key = tostring(kind) .. ":" .. name
    local rec = RI._recs[key]
    if rec then return rec end   -- (emptied when the game's recipes change: RI.reset, ensure)
    rec = { recipe = recipe, kind = kind, name = name }
    local dn = nil
    pcall(function() dn = recipe:getTranslationName() end)
    rec.displayName = (dn and dn ~= "") and tostring(dn) or name
    rec.needLearn = false
    pcall(function() if recipe:needToBeLearn() then rec.needLearn = true end end)
    pcall(function()
        local f = recipe:getOnAddToMenu()
        if f and f ~= "" then rec.onAdd = tostring(f) end
    end)
    rec.skills = {}
    pcall(function()
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local rs = recipe:getRequiredSkill(i)
            local pk = rs:getPerk()
            rec.skills[#rec.skills + 1] = { perk = pk, id = tostring(pk:getId()), level = rs:getLevel() }
        end
    end)
    RI._recs[key] = rec
    return rec
end

-- ---------------------------------------------------------------------------
-- WHAT THE GAME WOULD LIST
-- ---------------------------------------------------------------------------
-- the world's "See Not Known Recipes"
function RI.seeUnknown()
    local ok, v = pcall(function() return getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):getValue() end)
    return ok and v == true
end

-- A change to what the character knows: the known recipes' count and every level gained (Events.LevelPerk)
function RI.gen(player)
    local n = 0
    if player then pcall(function() n = player:getKnownRecipes():size() end) end
    return tostring(n) .. ":" .. tostring(RI._perkGen) .. ":" .. tostring(RI.seeUnknown())
end

-- answers kept per character until RI.gen changes: [player] = { gen, vis = {}, known = {} }
-- (RI.gen is asked at most every GEN_MS per character: a list of 800 recipes asks memoFor 800 times)
local GEN_MS = 500
local _memo = setmetatable({}, { __mode = "k" })
local function memoFor(player)
    local m = _memo[player]
    local t = now()
    if m and t < m.at then return m end
    local g = RI.gen(player)
    if not m or m.gen ~= g then
        m = { gen = g, vis = {}, known = {} }
        _memo[player] = m
    end
    m.at = t + GEN_MS
    return m
end
function RI.forget() _memo = setmetatable({}, { __mode = "k" }) end

-- false when the game would not list the recipe for the character (see the head of the file)
local function visibleNow(player, rec)
    if rec.needLearn and not RI.seeUnknown() then
        local known = false
        pcall(function() known = player:isRecipeActuallyKnown(rec.recipe) == true end)
        if not known then return false end
    end
    if rec.onAdd then
        local ok, r = pcall(callLuaBool, rec.onAdd, { player = player, recipe = rec.recipe, shouldShowAll = true })
        if not (ok and r == true) then return false end
    end
    return true
end
function RI.visible(player, recipeOrRec, kind)
    if not player or not recipeOrRec then return true end
    local rec = recipeOrRec
    if not rec.recipe then rec = RI.rec(recipeOrRec, kind or "craft") end
    if not rec then return true end
    local m = memoFor(player)
    local v = m.vis[rec]
    if v == nil then v = visibleNow(player, rec); m.vis[rec] = v end
    return v
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
local function knownMemo(player, rec)
    local m = memoFor(player)
    local k = m.known[rec]
    if k == nil then k = RI.known(player, rec) and true or false; m.known[rec] = k end
    return k
end

-- ---------------------------------------------------------------------------
-- THE ITEM CARD: the game's own list for the item
-- ---------------------------------------------------------------------------
function RI.usedInFor(player, scriptItem)
    local out = {}
    if not (player and scriptItem) then return out end
    local names = {}
    pcall(function()
        local l = scriptItem:getUsedInRecipes(player)   -- (a list the game reuses: copied at once)
        for i = 0, l:size() - 1 do names[#names + 1] = tostring(l:get(i)) end
    end)
    local m = sm()
    local seen = {}
    for _, nm in ipairs(names) do
        if not seen[nm] then
            seen[nm] = true
            local r, kind = nil, "craft"
            pcall(function() r = m:getCraftRecipe(nm) end)
            if not r then
                kind = "build"
                pcall(function() r = m:getBuildableRecipe(nm) end)
            end
            local rec = r and RI.rec(r, kind)
            if rec and RI.visible(player, rec) then out[#out + 1] = rec end
        end
    end
    return out
end

-- The item card's rows: up to max, known first, then by name; the rest's count
function RI.forCard(player, scriptItem, max)
    local rows = {}
    for _, rec in ipairs(RI.usedInFor(player, scriptItem)) do
        rows[#rows + 1] = { rec = rec, known = knownMemo(player, rec) }
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
-- routes it to ZeD; with ZeD's window off the game's own window opens, its query "*" as the game passes it)
function RI.open(player, rec)
    if not (player and rec and ISEntityUI) then return false end
    local fn = (rec.kind == "build") and ISEntityUI.OpenBuildWindow or ISEntityUI.OpenHandcraftWindow
    if not fn then return false end
    local ok = pcall(fn, player, nil, "*", nil, rec.recipe, nil)
    return ok
end

-- The rest of the item's recipes: the Craft tab with the item's name in its search (the game's
-- "craft with this item" way in)
function RI.openAll(player, fullType)
    if not (player and fullType and ISEntityUI and ISEntityUI.OpenHandcraftWindow) then return false end
    local ok = pcall(ISEntityUI.OpenHandcraftWindow, player, nil, "*", nil, nil, fullType)
    return ok
end

-- ---------------------------------------------------------------------------
-- THE SKILL INDEX: the levels each recipe needs, and the levels the game teaches it at
-- ---------------------------------------------------------------------------
local function addLevels(rec, byPerk, byAuto)
    local recipe = rec.recipe
    local autoSeen = {}
    for _, g in ipairs({ { "getAutoLearnAnySkillCount", "getAutoLearnAnySkill" }, { "getAutoLearnAllSkillCount", "getAutoLearnAllSkill" } }) do
        pcall(function()
            for i = 0, recipe[g[1]](recipe) - 1 do
                local rs = recipe[g[2]](recipe, i)
                local pid, lv = tostring(rs:getPerk():getId()), tonumber(rs:getLevel()) or 0
                local key = pid .. "#" .. tostring(lv)
                if lv > 0 and not autoSeen[key] then
                    autoSeen[key] = true
                    local p = byAuto[pid]
                    if not p then p = {}; byAuto[pid] = p end
                    p[lv] = p[lv] or {}
                    p[lv][#p[lv] + 1] = rec
                end
            end
        end)
    end
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
    local byPerk, byAuto = {}, {}
    local n = 0
    local names = {}   -- (a recipe in both lists is indexed once, as craft)
    for _, pair in ipairs({ { "getAllCraftRecipes", "craft" }, { "getAllBuildableRecipes", "build" } }) do
        local l = listOf(pair[1])
        if l then
            n = n + l:size()
            for i = 0, l:size() - 1 do
                local r = l:get(i)
                local rec = r and RI.rec(r, pair[2])
                if rec and not names[rec.name] then
                    names[rec.name] = true
                    pcall(addLevels, rec, byPerk, byAuto)
                end
            end
        end
    end
    RI._byPerk, RI._byAuto, RI._count = byPerk, byAuto, n
    RI._checkAt = now() + CHECK_MS
    RI.builds = RI.builds + 1
end

function RI.reset() RI._byPerk, RI._byAuto, RI._count = nil, nil, nil; RI._recs = {}; RI.forget() end

-- the index, rebuilt when the game's recipes changed
local function ensure()
    if not RI._byPerk then RI.build(); return end
    local t = now()
    if t >= RI._checkAt then
        RI._checkAt = t + CHECK_MS
        if countNow() ~= RI._count then RI._recs = {}; RI.forget(); RI.build() end
    end
end

function RI.atLevel(perkId)
    ensure()
    return (perkId and RI._byPerk[perkId]) or {}
end

function RI.taughtAt(perkId)
    ensure()
    return (perkId and RI._byAuto[perkId]) or {}
end

-- ZeD setup's "Recipes skills teach" (Settings.lua: Vanilla Access on, Vanilla and Vanilla Plus off)
function RI.showTaught()
    local S = ZeD.Settings
    if not (S and S.autoLearnOn) then return false end
    local ok, on = pcall(S.autoLearnOn)
    return ok and on == true
end

-- ---------------------------------------------------------------------------
-- THE SKILL CARD: the recipes that need each level still to come (the row's hover card, through the
-- Skills tab's extras), only those the game would list. The next level's recipes by name, a few; the rest
-- as counts.
-- ---------------------------------------------------------------------------
RI.NEXT_NAMES = 3
-- one block of lines: its head, each level still to come with its count, the first level's recipes named
local function levelLines(lines, player, by, cur, headKey)
    local first = true
    for lv = cur + 1, 10 do
        local l = {}
        for _, rec in ipairs(by[lv] or {}) do
            if RI.visible(player, rec) then l[#l + 1] = rec end
        end
        if #l > 0 then
            if first then lines[#lines + 1] = { text = ZeD.tr(headKey) } end
            lines[#lines + 1] = { text = ZeD.tr("UI_ZeD_Skills_UnlockLevel", lv), value = tostring(#l) }
            if first then
                first = false
                -- the next level's recipes by name
                table.sort(l, function(a, b) return a.displayName < b.displayName end)
                for i = 1, math.min(RI.NEXT_NAMES, #l) do
                    lines[#lines + 1] = { text = "  " .. l[i].displayName }
                end
                if #l > RI.NEXT_NAMES then
                    lines[#lines + 1] = { text = "  " .. ZeD.tr("UI_ZeD_Skills_UnlockMore", #l - RI.NEXT_NAMES) }
                end
            end
        end
    end
end
function RI.skillLines(player, perk, skill)
    local id = nil
    if perk then pcall(function() id = tostring(perk:getId()) end) end
    if not id then return nil end
    local cur = tonumber(skill and skill.level) or 0
    local lines = {}
    levelLines(lines, player, RI.atLevel(id), cur, "UI_ZeD_Skills_UnlockHead")
    if RI.showTaught() then levelLines(lines, player, RI.taughtAt(id), cur, "UI_ZeD_Skills_TaughtHead") end
    return (#lines > 0) and lines or nil
end

if ZeD.SkillsTab and ZeD.SkillsTab.addExtras then
    ZeD.SkillsTab.addExtras("ZeD_RecipeUnlocks", { cardLines = RI.skillLines })
end

if Events then
    -- built as a game starts (once, as the Craft tab's catalog), so the first card opened does not wait for it
    if Events.OnGameStart then Events.OnGameStart.Add(function() RI.reset(); pcall(RI.build) end) end
    -- a level gained: the kept answers go
    if Events.LevelPerk then Events.LevelPerk.Add(function() RI._perkGen = RI._perkGen + 1 end) end
end
