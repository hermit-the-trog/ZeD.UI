-- ZeD-UI/42/media/lua/client/ZeD/ZeD_HiddenFacts.lua
-- ============================================================================
-- THE HIDDEN FACTS OPEN WITH A FIND (punch list 109; the director, Nov 7 2026: "I can show you the TV schedule, but
-- you have to find the TV magazine first.")
--
-- Two guide pages the game keeps in the fiction, read live from the game:
--   * the TV schedule (the Television/Radio topic): the shows that teach a skill or a recipe in the next seven days,
--     from the stations' own broadcast scripts (ZomboidRadio's RadioScriptManager: each TV channel's script, its
--     broadcasts' start and end stamps and the codes on their lines, "FIS+1" or "RCP=Make Fishing Rod", the codes
--     the game's ISRadioInteractions turns into XP and recipes);
--   * the infection odds (the Zombie Attacks topic): which wounds can pass the infection in this world, from its
--     Transmission setting (the game's BodyPart: a bite always passes it unless the setting is None; a scratch or a
--     laceration only sometimes, and never with Saliva Only or None).
-- By preset (the director: "Vanilla plus gates them. Only vanilla access."): in Vanilla and Vanilla Plus a page opens
-- once the character has READ the find, like a recipe magazine (read once, kept for that character); in Vanilla
-- Access it is open from the start. ZeD setup's "Hidden facts" (Find first / Always, Settings.lua) holds the choice
-- for Custom. Until a page opens the guide says what more it could show and what to find.
--   TV schedule: Magazine: TV Monthly (Base.TVMagazine, Base.TVMagazine_New).
--   Infection odds: a First Aid book (Base.BookFirstAid1 to 5), the game's own medical literature; it spawns already
--     (no new loot), and volume I can be read by any character.
-- With "Always" the crafting card's How to learn also names the magazine that teaches a recipe (CraftingCore).
-- Never a live "you are infected": nothing here reads the character's body.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/ZeD_SurvivalGuide"

ZeD = ZeD or {}
ZeD.Finds = ZeD.Finds or {}
local F = ZeD.Finds

local function tr(k, ...) return ZeD.tr(k, ...) end

-- the finds: the items that open each page, and the game's own record of having read them
F.KINDS = {
    tv = { items = { "Base.TVMagazine", "Base.TVMagazine_New" }, literature = "TVMagazine_" },
    medical = { items = { "Base.BookFirstAid1", "Base.BookFirstAid2", "Base.BookFirstAid3", "Base.BookFirstAid4",
                          "Base.BookFirstAid5" }, pages = true },
}
local KIND_OF = {}
for kind, k in pairs(F.KINDS) do for _, ft in ipairs(k.items) do KIND_OF[ft] = kind end end
F.KIND_OF = KIND_OF

-- true while the pages show without the find (Vanilla Access, or Always picked by hand)
function F.always()
    local S = ZeD.Settings
    return (S and S.hiddenFactsAlways and S.hiddenFactsAlways()) and true or false
end

local function player(p)
    if p then return p end
    local ok, r = pcall(function() return getSpecificPlayer(0) end)
    return ok and r or nil
end

-- the game's record: a TV Monthly issue read (IsoGameCharacter.getReadLiterature keeps "TVMagazine_<month>_<year>",
-- the title ItemCodeOnCreate.onCreateTVMagazine gives the issue)
local function readLiterature(p, prefix)
    local ok, found = pcall(function()
        local it = p:getReadLiterature():keySet():iterator()
        while it:hasNext() do
            local key = tostring(it:next())
            if key:sub(1, #prefix) == prefix then return true end
        end
        return false
    end)
    return ok and found or false
end
-- the game's record: a skill book read to its last page (getAlreadyReadPages by the book's full type)
local function readToTheEnd(p, items)
    for _, ft in ipairs(items) do
        local ok, done = pcall(function()
            local si = getScriptManager():FindItem(ft)
            local pages = si and si:getNumberOfPages() or 0
            return pages > 0 and p:getAlreadyReadPages(ft) >= pages
        end)
        if ok and done then return true end
    end
    return false
end

-- true when the character has read the find for this page (or the pages need no find)
function F.has(kind, p)
    if F.always() then return true end
    local k = F.KINDS[kind]
    if not k then return false end
    p = player(p)
    if not p then return false end
    local okM, md = pcall(function() return p:getModData() end)
    if okM and md and md.ZeD_Finds and md.ZeD_Finds[kind] then return true end
    if k.literature and readLiterature(p, k.literature) then return true end
    if k.pages and readToTheEnd(p, k.items) then return true end
    return false
end

-- a find read: kept on the character (its mod data goes with the save)
function F.mark(p, ft)
    local kind = KIND_OF[tostring(ft or "")]
    if not (p and kind) then return false end
    local ok = pcall(function()
        local md = p:getModData()
        md.ZeD_Finds = md.ZeD_Finds or {}
        md.ZeD_Finds[kind] = true
    end)
    if ok and ZeD.Guide then ZeD.Guide._rulesC = {} end
    return ok
end

-- the read ends (ISReadABook:perform runs on the reader's own machine, in single player and on a server's client)
function F.hookReading()
    if F._hooked or not ISReadABook or not ISReadABook.perform then return end
    F._hooked = true
    local perform = ISReadABook.perform
    ISReadABook.perform = function(self, ...)
        pcall(function()
            local item, p = self.item, self.character
            local ft = item and item:getFullType()
            if not KIND_OF[tostring(ft or "")] then return end
            -- (a skill book counts when it was read to its last page)
            local pages = item:getNumberOfPages() or 0
            if pages > 0 and (item:getAlreadyReadPages() or 0) < pages then return end
            F.mark(p, ft)
        end)
        return perform(self, ...)
    end
end
F.hookReading()

-- ---------------------------------------------------------------------------
-- RECIPE SOURCES (Always: the crafting card names the magazine)
-- ---------------------------------------------------------------------------
-- recipe name -> the names of the items that teach it (the item scripts' LearnedRecipes), built once
function F.recipeIndex()
    if F._recipeIdx then return F._recipeIdx end
    local idx = {}
    pcall(function()
        local all = getScriptManager():getAllItems()
        for i = 0, all:size() - 1 do
            local it = all:get(i)
            local list = it:getLearnedRecipes()
            if list and list:size() > 0 then
                local name = tostring(it:getDisplayName() or it:getFullName())
                for j = 0, list:size() - 1 do
                    local r = tostring(list:get(j))
                    local t = idx[r]
                    if not t then t = {}; idx[r] = t end
                    local seen = false
                    for _, n in ipairs(t) do if n == name then seen = true; break end end
                    if not seen then t[#t + 1] = name end
                end
            end
        end
    end)
    F._recipeIdx = idx
    return idx
end
-- "Find <magazine>" for a recipe a magazine teaches, with Always; nil otherwise (the card keeps its own words)
function F.recipeSourceText(recipeName)
    if not F.always() or not recipeName then return nil end
    local names = F.recipeIndex()[tostring(recipeName)]
    if not names or #names == 0 then return nil end
    local shown = { names[1], names[2] }
    return tr("UI_ZeD_Craft_FindNamed", table.concat(shown, ", "))
end

-- ---------------------------------------------------------------------------
-- THE PAGES
-- ---------------------------------------------------------------------------
local W = ZeD.Guide
local Rules = W and W.Rules

-- a page not opened yet: what more it could show (the note), then what to find (one row, so both looks draw it)
local function lockedPage(title, more, find)
    return { title = title, cols = { tr("UI_ZeD_Hidden_ToAdd") }, rows = { { find } }, notes = { more }, locked = true }
end

local function clockText(mins)
    local h, m = math.floor(mins / 60), mins - math.floor(mins / 60) * 60
    local ok24, v24 = pcall(function() return getCore():getOptionClock24Hour() end)
    if ok24 and v24 == false then
        local h12 = h - math.floor(h / 12) * 12
        if h12 == 0 then h12 = 12 end
        return tr("UI_ZeD_MainMenu_Clock12", h12, string.format("%02d", m), tr(h >= 12 and "UI_ZeD_MainMenu_PM" or "UI_ZeD_MainMenu_AM"))
    end
    return string.format("%02d:%02d", h, m)
end
local function dayText(d)
    if d <= 0 then return tr("UI_ZeD_Hidden_Today") end
    if d == 1 then return tr("UI_ZeD_Hidden_Tomorrow") end
    return tr("UI_ZeD_Hidden_InDays", d)
end

-- the radio codes that teach a skill (ISRadioInteractions), by the game's perk name key
local SKILL_CODE = {
    SPR = "Sprinting", LFT = "Lightfooted", NIM = "Nimble", SNE = "Sneaking", BAA = "Axe", BUA = "Blunt",
    CRP = "Carpentry", COO = "Cooking", FRM = "Farming", DOC = "Doctor", ELC = "Electricity", MTL = "MetalWelding",
    FKN = "FlintKnapping", CRV = "Carving", AIM = "Aiming", REL = "Reloading", FIS = "Fishing", TRA = "Trapping",
    FOR = "Foraging", TAI = "Tailoring", MEC = "Mechanics", CMB = "Combat", SPE = "Spear", SBU = "SmallBlunt",
    LBA = "LongBlade", SBA = "SmallBlade",
}
F.SKILL_CODE = SKILL_CODE

-- (the broadcasts name a recipe as words, "Make Fishing Rod"; the craft recipe is MakeFishingRod)
local function recipeName(name)
    for _, id in ipairs({ name, (name:gsub("%s+", "")) }) do
        local ok, n = pcall(function()
            local r = getScriptManager():getCraftRecipe(id)
            return r and r:getTranslationName()
        end)
        if ok and n and tostring(n) ~= "" then return tostring(n) end
    end
    return name
end

-- what a broadcast teaches, in the game's words: "Fishing, Recipe: Make Fishing Rod" ("" when nothing)
local function teaches(bc)
    local skills, recipes, seen = {}, {}, {}
    local lines = bc:getLines()
    for i = 0, lines:size() - 1 do
        local codes = tostring(lines:get(i):getEffectsString() or "")
        for code in codes:gmatch("[^,]+") do
            code = code:gsub("^%s+", ""):gsub("%s+$", "")
            local key = code:sub(1, 3)
            local op = code:sub(4, 4)
            if key == "RCP" and op == "=" then
                local r = code:sub(5)
                if r ~= "" and not seen["r:" .. r] then
                    seen["r:" .. r] = true
                    recipes[#recipes + 1] = tr("UI_ZeD_Hidden_Recipe", recipeName(r))
                end
            elseif SKILL_CODE[key] and op == "+" and not seen[key] then
                seen[key] = true
                skills[#skills + 1] = getText("IGUI_perks_" .. SKILL_CODE[key])
            end
        end
    end
    for _, r in ipairs(recipes) do skills[#skills + 1] = r end
    return table.concat(skills, ", ")
end

F.DAYS = 7
-- the shows that teach, from now to DAYS days on: { at = minutes, day, time, channel, teaches }, by start
function F.schedule(days)
    days = days or F.DAYS
    local out = {}
    local ok = pcall(function()
        local sm = getZomboidRadio():getScriptManager()
        local now = sm:getCurrentTimeStamp()
        local today = math.floor(now / 1440)
        local list = sm:getChannelsList()
        for i = 0, list:size() - 1 do
            local ch = list:get(i)
            local sc = ch:IsTv() and ch:getCurrentScript()
            if sc then
                local base = sc:getStartDayStamp()
                local bl = sc:getBroadcastList()
                for j = 0, bl:size() - 1 do
                    local bc = bl:get(j)
                    local st, en = base + bc:getStartStamp(), base + bc:getEndStamp()
                    if en > now and st < (today + days) * 1440 then
                        local what = teaches(bc)
                        if what ~= "" then
                            local d = math.floor(st / 1440)
                            out[#out + 1] = { at = st, day = d - today, mins = st - d * 1440,
                                              channel = tostring(ch:GetName()), teaches = what }
                        end
                    end
                end
            end
        end
    end)
    if not ok then return nil end
    table.sort(out, function(a, b)
        if a.at ~= b.at then return a.at < b.at end
        return a.channel < b.channel
    end)
    return out
end

local function itemName(ft)
    local ok, n = pcall(function() return getItemNameFromFullType(ft) end)
    return (ok and n) and tostring(n) or ft
end

function F.tvPage()
    local title = tr("UI_ZeD_Hidden_TVTitle")
    if not F.has("tv") then
        return lockedPage(title, tr("UI_ZeD_Hidden_TVMore"), tr("UI_ZeD_Hidden_TVFind", itemName("Base.TVMagazine")))
    end
    local notes = { tr("UI_ZeD_Hidden_TVNote") }
    local cut = SandboxVars and tonumber(SandboxVars.LevelForMediaXPCutoff)
    if cut then notes[#notes + 1] = tr("UI_ZeD_Hidden_TVCutoff", cut) end
    local sched = F.schedule()
    if not sched or #sched == 0 then
        return { title = title, cols = { getText("IGUI_RadioChannel") }, rows = { { tr("UI_ZeD_Hidden_TVNone") } }, notes = notes }
    end
    local rows = {}
    for _, s in ipairs(sched) do
        rows[#rows + 1] = { dayText(s.day), clockText(s.mins), s.channel, s.teaches }
    end
    return { title = title, cols = { tr("UI_ZeD_Hidden_Day"), tr("UI_ZeD_Hidden_Time"), getText("IGUI_RadioChannel"), tr("UI_ZeD_Hidden_Teaches") },
             rows = rows, notes = notes }
end

-- which wounds can pass the infection, by the world's Transmission (1 Blood and Saliva, 2 Saliva Only, 3 Everyone's
-- Infected, 4 None; the game's BodyPart.SetBitten and generateZombieInfection)
function F.woundsFor(transmission)
    local A, S, N = tr("UI_ZeD_Hidden_Always"), tr("UI_ZeD_Hidden_Sometimes"), tr("UI_ZeD_Hidden_Never")
    if transmission == 4 then return N, N, N end
    if transmission == 2 then return A, N, N end
    return A, S, S
end

function F.infectionPage()
    local title = tr("UI_ZeD_Hidden_InfTitle")
    if not F.has("medical") then
        return lockedPage(title, tr("UI_ZeD_Hidden_InfMore"), tr("UI_ZeD_Hidden_InfFind", getText("IGUI_perks_Doctor")))
    end
    local ok, o = pcall(function() return getSandboxOptions():getOptionByName("ZombieLore.Transmission") end)
    if not (ok and o) then return nil end
    local okV, v, label = pcall(function() return o:getValue(), tostring(o:getTranslatedName()) end)
    if not okV then return nil end
    local okC, choice = pcall(function() return tostring(o:getValueTranslationByIndex(v)) end)
    if not okC then choice = tostring(v) end
    local bite, cut, scratch = F.woundsFor(tonumber(v))
    return { title = title, cols = { tr("UI_ZeD_Hidden_Wound"), tr("UI_ZeD_Hidden_Passes") },
             rows = { { getText("IGUI_health_Bitten"), bite }, { getText("IGUI_health_Cut"), cut }, { getText("IGUI_health_Scratched"), scratch } },
             notes = { tr("UI_ZeD_Rules_WorldIs", label, choice), tr("UI_ZeD_Hidden_InfNote") }, spoiler = true }
end

if Rules then
    -- Television/Radio: the schedule
    local tv = Rules.SurvivalGuide_television_title
    Rules.SurvivalGuide_television_title = function()
        local out = {}
        if tv then
            local ok, r = pcall(tv)
            if ok and r then
                if r.cols then out[1] = r else for _, t in ipairs(r) do out[#out + 1] = t end end
            end
        end
        local page = F.tvPage()
        if page then out[#out + 1] = page end
        return (#out > 0) and out or nil
    end
    -- Zombie Attacks: the world's infection settings as before, then the odds
    local za = Rules.SurvivalGuide_zombie_attacks_title
    Rules.SurvivalGuide_zombie_attacks_title = function()
        local out = {}
        if za then
            local ok, r = pcall(za)
            if ok and r then
                if r.cols then out[1] = r else for _, t in ipairs(r) do out[#out + 1] = t end end
            end
        end
        local page = F.infectionPage()
        if page then out[#out + 1] = page end
        return (#out > 0) and out or nil
    end
end
