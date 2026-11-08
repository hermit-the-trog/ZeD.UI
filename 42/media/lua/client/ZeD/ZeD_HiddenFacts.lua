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

-- Kahlua has no next(); whether a table has any entry.
local function hasAny(t) if type(t) ~= "table" then return false end for _ in pairs(t) do return true end return false end
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

-- the reader: the given one, else the player the guide was last opened for (W.open, wrapped below: in split screen
-- each player's own reading counts), else player 1
local function player(p)
    if p then return p end
    local pn = (ZeD.Guide and ZeD.Guide._pn) or 0
    local ok, r = pcall(function() return getSpecificPlayer(pn) end)
    return ok and r or nil
end
F.player = player

-- the game's record: a TV Monthly issue read (IsoGameCharacter.getReadLiterature keeps "TVMagazine_<month>_<year>",
-- the title ItemCodeOnCreate.onCreateTVMagazine gives the issue)
local function readLiterature(p, prefix)
    local ok, found = pcall(function()
        -- 42.21: a Java HashMap; Kahlua cannot call keySet() or iterator() on it, nor pairs() it. tostring(map) works
        -- and reads "[key=n, key=n]", so the key is found in that text.
        local map = p:getReadLiterature()
        if not map or map:isEmpty() then return false end
        local text = tostring(map)
        return (text:find("[" .. prefix, 1, true) or text:find(", " .. prefix, 1, true)) and true or false
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

-- a find read: kept on the character, in its mod data, as KillTracker keeps ZeD_Kills (it goes with the character's
-- save on a server too; the game's own reading records above are the fallback)
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

-- a timed action of reading came to its end: did it read the book to its last page? In single player the game has
-- moved the pages on (ISReadABook:update); on a server's client it never does (update counts pages only off the
-- client), so there the end itself is the answer: the action runs for the whole book (getDuration), and a book too
-- hard or already outgrown is stopped before it ends (update's forceStop), so perform never comes.
function F.readToEnd(action, client)
    local item, p = action.item, action.character
    local pages = item:getNumberOfPages() or 0
    if pages <= 0 then return true end
    if client then return true end
    if (item:getAlreadyReadPages() or 0) >= pages then return true end
    local ok, n = pcall(function() return p:getAlreadyReadPages(item:getFullType()) end)
    return ok and (tonumber(n) or 0) >= pages
end

-- the read ends (ISReadABook:perform runs on the reader's own machine, in single player and on a server's client)
function F.hookReading()
    if F._hooked or not ISReadABook or not ISReadABook.perform then return end
    F._hooked = true
    local perform = ISReadABook.perform
    ISReadABook.perform = function(self, ...)
        pcall(function()
            local item = self.item
            local ft = item and item:getFullType()
            if not KIND_OF[tostring(ft or "")] then return end
            if self.forceStopped then return end
            local okC, client = pcall(isClient)
            if F.readToEnd(self, okC and client == true) then F.mark(self.character, ft) end
        end)
        return perform(self, ...)
    end
end
F.hookReading()

-- ---------------------------------------------------------------------------
-- RECIPE SOURCES (Always: the crafting card names the magazine)
-- ---------------------------------------------------------------------------
-- recipe name -> the names of the items that teach it (the item scripts' LearnedRecipes), built once it builds whole.
-- A LearnedRecipes entry can be a group, "base:kitchentools": the craft recipes whose MetaRecipe it is
-- (CraftRecipe.getMetaRecipe) are its members, each taught by that item. A group with no members stays as it is.
-- A build that fails is not kept: the next card asks again.
local function addSource(idx, r, name)
    local t = idx[r]
    if not t then t = {}; idx[r] = t end
    for _, n in ipairs(t) do if n == name then return end end
    t[#t + 1] = name
end
function F.recipeIndex()
    if F._recipeIdx then return F._recipeIdx end
    local idx, groups = {}, {}
    local ok = pcall(function()
        local all = getScriptManager():getAllItems()
        for i = 0, all:size() - 1 do
            local it = all:get(i)
            local list = it:getLearnedRecipes()
            if list and list:size() > 0 then
                local name = tostring(it:getDisplayName() or it:getFullName())
                for j = 0, list:size() - 1 do
                    local r = tostring(list:get(j))
                    addSource(idx, r, name)
                    if r:find(":", 1, true) then groups[r] = true end
                end
            end
        end
    end)
    if not ok then return {} end
    if hasAny(groups) then
        local okG = pcall(function()
            local recipes = getScriptManager():getAllCraftRecipes()
            for i = 0, recipes:size() - 1 do
                local rc = recipes:get(i)
                local meta = rc:getMetaRecipe()
                local by = meta and groups[tostring(meta)] and idx[tostring(meta)]
                if by then
                    for _, name in ipairs(by) do addSource(idx, tostring(rc:getName()), name) end
                end
            end
        end)
        if not okG then return idx end   -- (the plain names hold; the groups are tried again next time)
    end
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
    -- (Build 42's newer skills)
    MAS = "Masonry", POT = "Pottery", BLA = "Blacksmith", GLA = "Glassmaking", HUS = "Husbandry", BUT = "Butchering",
    TRK = "Tracking",
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
-- the first daysSinceStart of this world, in minutes: the radio's daysSinceStart now less the nights survived (the
-- start month's offset, 0 for the default July start)
function F.startOffset()
    local ok, v = pcall(function()
        return (getZomboidRadio():getDaysSinceStart() - GameTime.getInstance():getNightsSurvived()) * 1440
    end)
    if ok and type(v) == "number" and v > 0 then return v end
    return 0
end
-- one TV channel's shows that teach, into out; true when the channel had a script to read
local function channelShows(ch, now, today, days, out)
    if not ch:IsTv() then return false end
    -- 42.21: RadioScriptManager.Load clears every channel's active script and only a RADIO_SAVE.txt line sets it again,
    -- so on a save without one (or one that says "none") getCurrentScript is nil on every channel although the
    -- channel still holds its scripts. Each channel's own "main" script (RadioData.xml startscript, keyed by name in
    -- the channel) is the daily programme, so that one is read when nothing is active.
    -- The stamps (zombie.radio.scripting, javap and bytecode, 42.21): all in MINUTES. RadioScript.setStartDayStamp(day)
    -- keeps startDayStamp = day * 1440, and RadioScript.UpdateScript(now) works on now - startDayStamp, compared with
    -- each broadcast's start and end stamp. So a broadcast airs at startDayStamp + its stamp, where its stamp is
    -- (RadioData.xml "day" * 1440 + minute of the day) from the SCRIPT'S start, and "now" (getCurrentTimeStamp) is
    -- ZomboidRadio's daysSinceStart * 1440 + hour * 60 + minute, daysSinceStart being the start month's offset
    -- (months * 30.5) plus the nights survived. A script lasts as long as its last broadcast ("main" about 28 days,
    -- loops 1) and then, with no exit option, the channel goes dark. RadioData sets every script to start at day 0
    -- when it is read; ZomboidRadio starts the channels at daysSinceStart when the world begins.
    local sc = ch:getCurrentScript()
    local dormant = false
    if not sc and ch.getRadioScript then sc = ch:getRadioScript("main"); dormant = sc ~= nil end
    if not sc then return false end
    local base = sc:getStartDayStamp()
    -- (a script never started in this run is still at RadioData's day 0: the channels start at the world's first
    -- daysSinceStart, the start month's offset, so that is where it airs from)
    if dormant and base == 0 then base = F.startOffset() end
    local bl = sc:getBroadcastList()
    local stat = F.stat
    if stat then stat.channels = stat.channels + 1; if dormant then stat.dormant = stat.dormant + 1 end end
    for j = 0, bl:size() - 1 do
        local bc = bl:get(j)
        local st, en = base + bc:getStartStamp(), base + bc:getEndStamp()
        if stat then
            stat.broadcasts = stat.broadcasts + 1
            if stat.first == nil or st < stat.first then stat.first = st end
            if stat.last == nil or en > stat.last then stat.last = en end
        end
        if en > now and st < (today + days) * 1440 then
            if stat then stat.inWindow = stat.inWindow + 1 end
            local what = teaches(bc)
            if what ~= "" then
                local d = math.floor(st / 1440)
                out[#out + 1] = { at = st, day = d - today, mins = st - d * 1440,
                                  channel = tostring(ch:GetName()), teaches = what }
            end
        end
    end
    return true
end
-- the shows that teach, from now to DAYS days on: { at = minutes, day, time, channel, teaches }, by start; nil when
-- no TV channel has a script here (a server's client: the server runs the broadcasts and keeps their scripts). Each
-- channel is read on its own, so one that fails leaves the others listed.
function F.schedule(days)
    days = days or F.DAYS
    local out, read = {}, 0
    -- (what the last read saw, for QA: zedqa_b8_tvstamps.lua prints it)
    F.stat = { channels = 0, dormant = 0, broadcasts = 0, inWindow = 0 }
    local ok = pcall(function()
        local sm = getZomboidRadio():getScriptManager()
        local now = sm:getCurrentTimeStamp()
        local today = math.floor(now / 1440)
        local list = sm:getChannelsList()
        for i = 0, list:size() - 1 do
            local okC, had = pcall(channelShows, list:get(i), now, today, days, out)
            if okC and had then read = read + 1 end
        end
    end)
    if not ok or read == 0 then return nil end
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
    if not sched then
        return { title = title, cols = { getText("IGUI_RadioChannel") }, rows = { { tr("UI_ZeD_Hidden_TVUnavailable") } }, notes = notes }
    end
    if #sched == 0 then
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
    local notes = {}
    -- (Mortality Never, its 7th choice: the infection is caught but never kills; said first, so "Always" never reads as
    -- a death sentence)
    local okM, mo = pcall(function() return getSandboxOptions():getOptionByName("ZombieLore.Mortality") end)
    if okM and mo then
        local okMV, mv, mlabel = pcall(function() return mo:getValue(), tostring(mo:getTranslatedName()) end)
        if okMV and tonumber(mv) == 7 then
            local okMC, mchoice = pcall(function() return tostring(mo:getValueTranslationByIndex(mv)) end)
            notes[#notes + 1] = tr("UI_ZeD_Hidden_NotFatal", mlabel, okMC and mchoice or tostring(mv))
        end
    end
    notes[#notes + 1] = tr("UI_ZeD_Rules_WorldIs", label, choice)
    notes[#notes + 1] = tr("UI_ZeD_Hidden_InfNote")
    return { title = title, cols = { tr("UI_ZeD_Hidden_Wound"), tr("UI_ZeD_Hidden_Passes") },
             rows = { { getText("IGUI_health_Bitten"), bite }, { getText("IGUI_health_Cut"), cut }, { getText("IGUI_health_Scratched"), scratch } },
             notes = notes, spoiler = true }
end

-- the guide opened: note for whom, so the pages read that player's finds (split screen)
if W and W.open and not F._openHooked then
    F._openHooked = true
    local open = W.open
    W.open = function(pn, ...)
        W._pn = pn or 0
        return open(pn, ...)
    end
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
