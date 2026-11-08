-- ZeDUI/tools/qa/hidden_facts_sim.lua  (Nov 7 2026, Build; punch list 109, "The hidden facts open with a find")
-- The guide's TV schedule and infection odds, with no game running. The real Settings.lua and ZeD_HiddenFacts.lua run
-- on Lua 5.1 stubs of the game:
--   Settings: the new "Hidden facts" choice (Find first / Always), Find first for a new player, in the additions'
--     IDS, Find first in Vanilla and Vanilla Plus, Always in Vanilla Access; a player saved on Vanilla Access before it
--     existed gets Always (no drop to Custom); its row in ZeD setup's additions group.
--   Locked and unlocked, per preset: in Vanilla and Vanilla Plus both pages are locked until the find is read, and the
--     locked page says what more it could show and what to find (the game's own item name); in Vanilla Access both
--     open with nothing read; the world's infection table the guide had before stays first on its topic.
--   Reading: ISReadABook:perform on TV Monthly opens the schedule only; a First Aid book read part way opens nothing,
--     read to the last page opens the odds; the game's own records open them too (a "TVMagazine_<m>_<y>" title in
--     getReadLiterature, a First Aid book's pages in getAlreadyReadPages); other reading opens nothing.
--   The live schedule: the game's real media/radio/RadioData.xml loaded into stub channels, scripts, broadcasts and
--     lines (the getters the code calls, as javap lists them): only TV channels, only shows that teach (a skill code
--     with "+" or RCP=), from now to seven days on, in time order, Today / Tomorrow / In n days, 24-hour and 12-hour
--     clocks, the skill named by the game's perk key and the recipe by its craft recipe's name; a radio station's
--     teaching lines never listed.
--   The odds: bite / laceration / scratch for each Transmission choice (the game's BodyPart rules); the world's
--     choice in the note; never anything about this character's body.
--   Recipe sources: the card's words stay as they were until Always, then "Find <magazine>".
--   Every key the file asks for in all 28 languages, with the English %n markers.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/hidden_facts_sim.lua
-- It prints FAIL lines and a last line "hidden_facts_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]hidden_facts_sim%.lua$", "")
local PZ = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/"
local LUA = ROOT .. "42/media/lua/"

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
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- THE WORDS (UI.json, every language; the game's own keys the code borrows)
-- ---------------------------------------------------------------------------
local function loadJson(path)
    local s = readFile(path)
    if not s then return nil end
    local t = {}
    for k, v in s:gmatch('"([%w_%.]+)"%s*:%s*"(.-[^\\])",?%s*\r?\n') do
        t[k] = v:gsub('\\"', '"'):gsub("\\\\", "\\")
    end
    return t
end
local LANGS = { "EN", "AR", "CA", "CH", "CN", "CS", "DA", "DE", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
                "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local UI = {}
for _, l in ipairs(LANGS) do UI[l] = loadJson(LUA .. "shared/Translate/" .. l .. "/UI.json") end
local EN = UI.EN or {}
local GAME = {
    IGUI_RadioChannel = "Channel", IGUI_health_Bitten = "Bitten", IGUI_health_Cut = "Laceration",
    IGUI_health_Scratched = "Scratched", IGUI_perks_Doctor = "First Aid", IGUI_perks_Fishing = "Fishing",
    IGUI_perks_Cooking = "Cooking", IGUI_perks_Carpentry = "Carpentry", IGUI_perks_Foraging = "Foraging",
    IGUI_perks_Trapping = "Trapping", IGUI_perks_Farming = "Farming", UI_Off = "Off", UI_On = "On",
    IGUI_perks_Masonry = "Masonry", IGUI_perks_Pottery = "Pottery", IGUI_perks_Blacksmith = "Blacksmith",
    IGUI_perks_Glassmaking = "Glassmaking", IGUI_perks_Husbandry = "Husbandry", IGUI_perks_Butchering = "Butchering",
    IGUI_perks_Tracking = "Tracking",
    Sandbox_Custom = "Custom",
}
local function fill(s, ...)
    local a = { ... }
    return (tostring(s):gsub("%%(%d)", function(d) return tostring(a[tonumber(d)] or "") end))
end
local asked = {}
function getText(k, ...)
    if GAME[k] then return fill(GAME[k], ...) end
    if EN[k] then return fill(EN[k], ...) end
    return k
end
getTextOrNull = getText

ZeD = { tr = function(k, ...) asked[k] = true; return getText(k, ...) end }

-- ---------------------------------------------------------------------------
-- STUBS: options, files, events
-- ---------------------------------------------------------------------------
local FILES = {}
function getFileReader(name)
    local s = FILES[name]
    if not s then return nil end
    local lines, i = {}, 0
    for l in (s .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
    return { readLine = function() i = i + 1; return lines[i] end, close = noop }
end
function getFileWriter(name) return { write = noop, close = noop } end
Events = setmetatable({}, { __index = function(t, k) local e = { Add = noop, Remove = noop }; rawset(t, k, e); return e end })

local function newOption(id)
    local o = { id = id, values = {}, selected = 1 }
    function o:addItem(name, isDefault)
        self.values[#self.values + 1] = name
        if isDefault then self.selected = #self.values end
    end
    function o:getValue() return self.selected end
    function o:setValue(v) self.selected = v end
    return o
end
local function newOpts()
    local opts = { dict = {} }
    local function add(self, id)
        local o = newOption(id)
        self.dict[id] = o
        return o
    end
    return setmetatable(opts, { __index = function(t, k)
        if k == "addComboBox" or k == "addTickBox" or k == "addMultipleTickBox" or k == "addSlider" then return add end
        return noop
    end })
end
local lastOpts
PZAPI = { ModOptions = { create = function() lastOpts = newOpts(); return lastOpts end, save = noop, load = noop } }
local realRequire = require
require = function() end
getCore = function() return { getOptionClock24Hour = function() return CLOCK24 ~= false end } end
-- (split screen: player 2 is its own character)
getSpecificPlayer = function(pn) if pn == 1 then return PLAYER2 end return PLAYER end
getPlayer = function() return PLAYER end
CLOCK24 = true
CLIENT = false
isClient = function() return CLIENT end

local function loadSettings(ini)
    FILES["ModOptions.ini"] = ini
    ZeD.Settings = nil
    local chunk, err = loadfile(LUA .. "client/ZeD/Settings.lua")
    if not chunk then return nil, err end
    local ok, e = pcall(chunk)
    if not ok then return nil, e end
    return lastOpts
end

-- ---------------------------------------------------------------------------
-- SETTINGS
-- ---------------------------------------------------------------------------
section("Settings: the Hidden facts choice and the presets")
local opts, err = loadSettings(nil)
check("Settings.lua loads", opts ~= nil, err)
opts = opts or newOpts()
local hf = opts.dict.hiddenFacts
check("a hiddenFacts option", hf ~= nil)
check("its items: Find first, Always", hf and hf.values[1] == "Find first" and hf.values[2] == "Always" and #hf.values == 2,
      hf and table.concat(hf.values, "/"))
check("Find first for a new player", hf and hf:getValue() == 1)
check("hiddenFactsAlways() false on Find first", ZeD.Settings and ZeD.Settings.hiddenFactsAlways and ZeD.Settings.hiddenFactsAlways() == false)
check("its name key noted", hf and hf.zedNameKey == "UI_ZeD_Settings_HiddenFacts")
local inIds = false
for _, id in ipairs(ZeD.Settings and ZeD.Settings.ADDITION_IDS or {}) do if id == "hiddenFacts" then inIds = true end end
check("an addition (in ADDITION_IDS)", inIds)
local P = ZeD.Settings and ZeD.Settings.ADDITION_PRESETS or {}
check("Vanilla: Find first", P[1] and P[1].hiddenFacts == 1)
check("Vanilla Plus: Find first", P[2] and P[2].hiddenFacts == 1)
check("Vanilla Access: Always", P[3] and P[3].hiddenFacts == 2)
-- a preset picked sets it (the additions' onChange, as ZeD setup calls it)
local preset = opts.dict.additionsPreset
if preset and preset.onChange then
    preset.onChange(nil, 3)
    check("picking Vanilla Access sets Always", hf:getValue() == 2)
    preset.onChange(nil, 2)
    check("picking Vanilla Plus sets Find first", hf:getValue() == 1)
    preset.onChange(nil, 3)
    check("hiddenFactsAlways() true on Always", ZeD.Settings.hiddenFactsAlways() == true)
    preset.onChange(nil, 1)
else
    check("the preset's onChange", false)
end
-- a player saved on Vanilla Access before the row existed keeps Vanilla Access
local accessIni = table.concat({ "|ZeD_UI|additionsPreset|3", "|ZeD_UI|ammoBox|2", "|ZeD_UI|devicesStyle|2", "|ZeD_UI|identityStyle|2" }, "\n")
local o2 = loadSettings(accessIni)
check("an older Vanilla Access save: Always", o2 and o2.dict.hiddenFacts and o2.dict.hiddenFacts:getValue() == 2)
local o3 = loadSettings(table.concat({ "|ZeD_UI|additionsPreset|2", "|ZeD_UI|ammoBox|2" }, "\n"))
check("an older Vanilla Plus save: Find first", o3 and o3.dict.hiddenFacts and o3.dict.hiddenFacts:getValue() == 1)
local o4 = loadSettings(table.concat({ "|ZeD_UI|additionsPreset|3", "|ZeD_UI|hiddenFacts|1" }, "\n"))
check("a saved Find first on Vanilla Access is left as saved", o4 and o4.dict.hiddenFacts and o4.dict.hiddenFacts:getValue() == 1)
local groups = readFile(LUA .. "client/ZeD/ZeD_MainMenuOptionGroups.lua") or ""
local addGroup = groups:match('"UI_ZeD_Options_ZedAdditions".-}%s*}%s*},')
check("its row in ZeD setup's additions group", addGroup and addGroup:find('{ "hiddenFacts", "radio" }', 1, true) ~= nil)

section("Settings: the beta 6 repair still runs with newer additions")
-- a player beta 6 moved to Custom: Vanilla Access in every row but Identity (Immersive), no line for any newer row
local B6 = { ammoBox = 2, readMarks = 2, readNext = 2, dimRead = 2, dashLamps = 2, moodleNotices = 2, messagesCatch = 2,
             messagesToast = 2, putBack = 2, sandboxInGame = 2, loadouts = 2, restock = 3, devicesStyle = 2, watchStyle = 2,
             dashStyle = 2, guideStyle = 2, modsStyle = 2, identityStyle = 1, haloBubble = 2 }
local function beta6(extra)
    local lines = { "|ZeD_UI|additionsPreset|4" }
    for id, v in pairs(B6) do lines[#lines + 1] = "|ZeD_UI|" .. id .. "|" .. v end
    for id, v in pairs(extra or {}) do lines[#lines + 1] = "|ZeD_UI|" .. id .. "|" .. v end
    local o = loadSettings(table.concat(lines, "\n"))
    if not o then return nil end
    -- (the game reads the file into the options; the stub does it here)
    for id, v in pairs(B6) do if o.dict[id] then o.dict[id]:setValue(v) end end
    for id, v in pairs(extra or {}) do if o.dict[id] then o.dict[id]:setValue(v) end end
    o.dict.additionsPreset:setValue(4)
    ZeD.Settings.reconcileAdditions()
    return o
end
local r6 = beta6()
check("beta 6 repair: Identity set Simple", r6 and r6.dict.identityStyle:getValue() == 2)
check("beta 6 repair: Hidden facts (no saved line) set Always", r6 and r6.dict.hiddenFacts:getValue() == 2)
check("beta 6 repair: every newer row with no saved line (Recipes skills teach) set to Vanilla Access",
      r6 and r6.dict.autoLearn ~= nil and r6.dict.autoLearn:getValue() == 2)
check("beta 6 repair: the preset reads Vanilla Access", r6 and r6.dict.additionsPreset:getValue() == 3,
      r6 and r6.dict.additionsPreset:getValue())
local r7 = beta6({ hiddenFacts = 1 })
check("beta 6 repair: a saved Find first is kept", r7 and r7.dict.hiddenFacts:getValue() == 1)
check("beta 6 repair: Identity still repaired beside a saved newer row", r7 and r7.dict.identityStyle:getValue() == 2)
local r8 = beta6({ ammoBox = 1 })
check("beta 6 repair: a real hand pick (Ammo off) is not repaired", r8 and r8.dict.identityStyle:getValue() == 1)
local st = readFile(LUA .. "client/ZeD/Settings.lua") or ""
local rep = st:match("local function repairVanillaAccess%(%).-\n    end\r?\n")
check("beta 6 repair: compares the beta 6 rows only, not every preset row", rep and rep:find("REPAIR_IDS", 1, true) ~= nil
      and not rep:find("for id, v in pairs(set) do\r?\n%s*local want"))

-- back to a fresh Settings for the pages (Vanilla)
opts = loadSettings(nil) or newOpts()
local function setPreset(i)
    opts.dict.additionsPreset.onChange(nil, i)
    opts.dict.additionsPreset:setValue(i)
end

-- ---------------------------------------------------------------------------
-- THE GAME: player, items, scripts, sandbox, radio
-- ---------------------------------------------------------------------------
local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end
local function newPlayer()
    local p = { md = {}, lit = {}, pages = {} }
    function p:getModData() return self.md end
    function p:getReadLiterature()
        local keys = {}
        for k in pairs(self.lit) do keys[#keys + 1] = k end
        return { keySet = function() return { iterator = function()
            local i = 0
            return { hasNext = function() return i < #keys end, next = function() i = i + 1; return keys[i] end }
        end } end }
    end
    function p:getAlreadyReadPages(ft) return self.pages[ft] or 0 end
    return p
end
PLAYER = newPlayer()
PLAYER2 = newPlayer()

local PAGES = { ["Base.BookFirstAid1"] = 220, ["Base.BookFirstAid2"] = 260, ["Base.BookFirstAid3"] = 300,
                ["Base.BookFirstAid4"] = 340, ["Base.BookFirstAid5"] = 380 }
local NAMES = { ["Base.TVMagazine"] = "Magazine: TV Monthly", ["Base.TVMagazine_New"] = "Magazine: TV Monthly" }
function getItemNameFromFullType(ft) return NAMES[ft] or ft end
local SCRIPT_ITEMS = {
    { full = "Base.SmithingMag1", name = "Smithing Vol. 1", learned = { "Forge_Tongs", "MakeCrudeWhetstone" } },
    { full = "Base.FishingMag1", name = "Angler USA Magazine Vol. 1", learned = { "MakeFishingRod" } },
    { full = "Base.FishingMag2", name = "Angler USA Magazine Vol. 2", learned = { "MakeFishingRod" } },
    { full = "Base.Apple", name = "Apple" },
    { full = "Base.SmithingMag2", name = "Smithing Vol. 2", learned = { "base:kitchentools", "base:nogroup" } },
}
local CRAFT = { MakeFishingRod = "Make Fishing Rod", MakeCakeBatter = "Make Cake Batter", MakePieDough = "Make Pie Dough",
                MakeCrateTrap = "Make Crate Trap" }
-- the craft recipes with a MetaRecipe group (recipes_blacksmith_cookware.txt: MetaRecipe = base:kitchentools)
local CRAFT_ALL = { { "Forge_Cooking_Pot", "base:kitchentools" }, { "Forge_Saucepan", "base:kitchentools" }, { "MakeFishingRod" } }
local ITEMS_FAIL = 0
local RADIO
function getScriptManager()
    return {
        FindItem = function(_, ft) return PAGES[ft] and { getNumberOfPages = function() return PAGES[ft] end } or nil end,
        getAllCraftRecipes = function()
            local t = {}
            for _, c in ipairs(CRAFT_ALL) do
                t[#t + 1] = { getName = function() return c[1] end, getMetaRecipe = function() return c[2] end }
            end
            return jlist(t)
        end,
        getAllItems = function()
            if ITEMS_FAIL > 0 then ITEMS_FAIL = ITEMS_FAIL - 1; error("scripts not loaded yet") end
            local t = {}
            for _, it in ipairs(SCRIPT_ITEMS) do
                t[#t + 1] = { getLearnedRecipes = function() return it.learned and jlist(it.learned) or nil end,
                              getDisplayName = function() return it.name end, getFullName = function() return it.full end }
            end
            return jlist(t)
        end,
        getCraftRecipe = function(_, id)
            return CRAFT[id] and { getTranslationName = function() return CRAFT[id] end } or nil
        end,
    }
end
local TRANSMISSION, MORTALITY = 1, 5
local TLABELS = { "Blood and Saliva", "Saliva Only", "Everyone's Infected", "None" }
local MLABELS = { "Instant", "0-30 Seconds", "0-1 Minutes", "0-12 Hours", "2-3 Days", "1-2 Weeks", "Never" }
function getSandboxOptions()
    return { getOptionByName = function(_, name)
        if name == "ZombieLore.Mortality" then
            return { getValue = function() return MORTALITY end, getTranslatedName = function() return "Infection Mortality" end,
                     getValueTranslationByIndex = function(_, i) return MLABELS[i] end }
        end
        if name ~= "ZombieLore.Transmission" then return nil end
        return { getValue = function() return TRANSMISSION end, getTranslatedName = function() return "Transmission" end,
                 getValueTranslationByIndex = function(_, i) return TLABELS[i] end }
    end }
end
SandboxVars = { LevelForMediaXPCutoff = 3 }
function getZomboidRadio() return RADIO end

-- the game's broadcast scripts from RadioData.xml, as the stub channels the code reads
local function loadRadio()
    local xml = readFile(PZ .. "radio/RadioData.xml")
    if not xml then return nil end
    local channels = {}
    for head, body in xml:gmatch("<ChannelEntry(.-)>(.-)</ChannelEntry>") do
        local name, cat, start = head:match('name="(.-)"'), head:match('cat="(.-)"'), head:match('startscript="(.-)"')
        local scripts = {}
        for shead, sbody in body:gmatch("<ScriptEntry(.-)>(.-)</ScriptEntry>") do
            local bcs = {}
            -- (a broadcast with lines, and an empty one written <BroadcastEntry ... />)
            for bhead, bbody in sbody:gmatch("<BroadcastEntry([^>]-[^/])>(.-)</BroadcastEntry>") do
                local lines = {}
                for lhead in bbody:gmatch("<LineEntry(.-)/>") do
                    local codes = lhead:match('codes="(.-)"')
                    lines[#lines + 1] = { getEffectsString = function() return codes end }
                end
                local st, en = tonumber(bhead:match('timestamp="(%d+)"')), tonumber(bhead:match('endstamp="(%d+)"'))
                if bhead:match('isSegment="false"') then
                    bcs[#bcs + 1] = { getStartStamp = function() return st end, getEndStamp = function() return en end,
                                      getLines = function() return jlist(lines) end }
                end
            end
            scripts[shead:match('name="(.-)"')] = { getStartDayStamp = function() return 0 end,
                                                     getBroadcastList = function() return jlist(bcs) end, n = #bcs }
        end
        channels[#channels + 1] = { GetName = function() return name end, IsTv = function() return cat == "Television" end,
                                    getCurrentScript = function() return scripts[start] end, cat = cat, script = scripts[start] }
    end
    return channels
end
local CHANNELS = loadRadio()
local NOW = 0
local function setRadio(channels, now)
    NOW = now
    RADIO = { getScriptManager = function() return {
        getCurrentTimeStamp = function() return NOW end,
        getChannelsList = function() return jlist(channels) end,
    } end }
end

-- the guide: its Rules table, with the world's infection table it had before (ZeD_SurvivalGuide.lua)
local OPENED = {}
ZeD.Guide = { Rules = {}, _rulesC = {}, open = function(pn, want) OPENED[#OPENED + 1] = { pn, want } end }
local OLD_INF = { title = "The infection in this world", cols = { "Setting", "This world" }, rows = { { "Transmission", "Blood and Saliva" } }, spoiler = true }
ZeD.Guide.Rules.SurvivalGuide_zombie_attacks_title = function() return OLD_INF end

-- ISReadABook, as the game has it (shared, loaded before the client)
local performed = 0
ISReadABook = { perform = function() performed = performed + 1 end }

local chunk, lerr = loadfile(LUA .. "client/ZeD/ZeD_HiddenFacts.lua")
check("ZeD_HiddenFacts.lua loads", chunk ~= nil, lerr)
if not chunk then
    print(string.format("hidden_facts_sim: %d checks, %d failed", checks, failed))
    os.exit(1)
end
local okL, eL = pcall(chunk)
check("ZeD_HiddenFacts.lua runs", okL, eL)
local F = ZeD.Finds or {}
local R = ZeD.Guide.Rules
local function pages(key)
    local r = R[key] and R[key]()
    if r and r.cols then r = { r } end
    return r or {}
end
local function last(key) local p = pages(key); return p[#p] end
local function read(ft, readPages, total, who, stopped)
    local item = { getFullType = function() return ft end, getNumberOfPages = function() return total or -1 end,
                   getAlreadyReadPages = function() return readPages or 0 end }
    ISReadABook.perform({ item = item, character = who or PLAYER, forceStopped = stopped })
end
setRadio(CHANNELS or {}, 2 * 1440 + 10 * 60)

-- ---------------------------------------------------------------------------
-- LOCKED AND UNLOCKED, PER PRESET
-- ---------------------------------------------------------------------------
for _, pr in ipairs({ { 1, "Vanilla" }, { 2, "Vanilla Plus" } }) do
    section(pr[2] .. ": locked until the find is read")
    setPreset(pr[1])
    PLAYER = newPlayer()
    check(pr[2] .. ": not Always", F.always and F.always() == false)
    local tv = last("SurvivalGuide_television_title")
    check(pr[2] .. ": a TV page on Television/Radio", tv ~= nil)
    check(pr[2] .. ": the TV page locked", tv and tv.locked == true)
    check(pr[2] .. ": its title", tv and tv.title == "TV schedule", tv and tv.title)
    check(pr[2] .. ": what more it could show", tv and tv.notes and tv.notes[1] == EN.UI_ZeD_Hidden_TVMore)
    check(pr[2] .. ": what to find, by the game's item name", tv and tv.rows[1] and tv.rows[1][1] == "Read Magazine: TV Monthly to add the broadcast schedule here.",
          tv and tv.rows[1] and tv.rows[1][1])
    check(pr[2] .. ": one column, one row (both looks draw it)", tv and #tv.cols == 1 and #tv.rows == 1)
    local inf = pages("SurvivalGuide_zombie_attacks_title")
    check(pr[2] .. ": the world's infection table still first", inf[1] == OLD_INF)
    check(pr[2] .. ": the odds locked", inf[2] and inf[2].locked == true)
    check(pr[2] .. ": the odds say what to find", inf[2] and inf[2].rows[1][1] == "Read a First Aid book to add the infection odds here.",
          inf[2] and inf[2].rows[1][1])
    check(pr[2] .. ": the odds say what more", inf[2] and inf[2].notes[1] == EN.UI_ZeD_Hidden_InfMore)
    check(pr[2] .. ": no wound row while locked", inf[2] and #inf[2].rows == 1)
end

section("Reading the finds (Vanilla)")
setPreset(1)
PLAYER = newPlayer()
local before = performed
read("Base.Apple")
check("the game's perform still runs", performed == before + 1)
check("other reading opens nothing", last("SurvivalGuide_television_title").locked and last("SurvivalGuide_zombie_attacks_title").locked)
read("Base.TVMagazine")
check("TV Monthly read: the schedule opens", not last("SurvivalGuide_television_title").locked)
check("TV Monthly read: kept on the character", PLAYER.md.ZeD_Finds and PLAYER.md.ZeD_Finds.tv == true)
check("TV Monthly read: the odds stay locked", last("SurvivalGuide_zombie_attacks_title").locked == true)
read("Base.BookFirstAid1", 100, 220)
check("a First Aid book read part way: the odds stay locked", last("SurvivalGuide_zombie_attacks_title").locked == true)
read("Base.BookFirstAid1", 220, 220)
check("a First Aid book read to the end: the odds open", not last("SurvivalGuide_zombie_attacks_title").locked)
PLAYER = newPlayer()
read("Base.TVMagazine_New")
check("the new-issue TV Monthly opens it too", not last("SurvivalGuide_television_title").locked)
read("Base.BookFirstAid4", 340, 340)
check("any First Aid volume opens the odds", not last("SurvivalGuide_zombie_attacks_title").locked)

section("The game's own records (no ZeD mark)")
PLAYER = newPlayer()
PLAYER.lit["Book_Fantasy_3"] = 1
check("another title: locked", last("SurvivalGuide_television_title").locked == true)
PLAYER.lit["TVMagazine_7_1993"] = 1
check("a TV Monthly issue in getReadLiterature: open", not last("SurvivalGuide_television_title").locked)
PLAYER.pages["Base.BookFirstAid2"] = 120
check("a First Aid book part read: locked", last("SurvivalGuide_zombie_attacks_title").locked == true)
PLAYER.pages["Base.BookFirstAid2"] = 260
check("a First Aid book's pages all read: open", not last("SurvivalGuide_zombie_attacks_title").locked)

section("Vanilla Access: open with nothing read")
setPreset(3)
PLAYER = newPlayer()
check("Always", F.always() == true)
check("the schedule open", not last("SurvivalGuide_television_title").locked)
check("the odds open", not last("SurvivalGuide_zombie_attacks_title").locked)
check("the world's table still first", pages("SurvivalGuide_zombie_attacks_title")[1] == OLD_INF)
setPreset(4)   -- Custom keeps the hand picks (here Always, from Vanilla Access)
check("Custom with Always: open", not last("SurvivalGuide_television_title").locked)
opts.dict.hiddenFacts:setValue(1)
check("Custom with Find first: locked", last("SurvivalGuide_television_title").locked == true)

section("Split screen: each player's own reading")
setPreset(1)
PLAYER, PLAYER2 = newPlayer(), newPlayer()
read("Base.TVMagazine", nil, nil, PLAYER2)
ZeD.Guide.open(1, "SurvivalGuide_television_title")
check("the guide's own open still runs", OPENED[#OPENED] and OPENED[#OPENED][1] == 1 and OPENED[#OPENED][2] == "SurvivalGuide_television_title")
check("player 2 read TV Monthly, opens the guide: open", not last("SurvivalGuide_television_title").locked)
ZeD.Guide.open(0)
check("player 1 has not, opens the guide: locked", last("SurvivalGuide_television_title").locked == true)
read("Base.BookFirstAid1", 220, 220, PLAYER)
check("player 1 read a First Aid book: the odds open for player 1", not last("SurvivalGuide_zombie_attacks_title").locked)
ZeD.Guide.open(1)
check("... and stay locked for player 2", last("SurvivalGuide_zombie_attacks_title").locked == true)
ZeD.Guide.open(0)

section("Multiplayer finds: a server's client")
PLAYER = newPlayer()
CLIENT = true
-- (on a client the game never moves the pages on: the item and the character both still say 0)
read("Base.BookFirstAid2", 0, 260)
check("client: a First Aid book read to the end of the action opens the odds", not last("SurvivalGuide_zombie_attacks_title").locked)
check("client: kept on the character, as KillTracker keeps its marks", PLAYER.md.ZeD_Finds and PLAYER.md.ZeD_Finds.medical == true)
PLAYER = newPlayer()
read("Base.BookFirstAid2", 0, 260, nil, true)
check("client: a reading stopped early opens nothing", last("SurvivalGuide_zombie_attacks_title").locked == true)
CLIENT = false
read("Base.BookFirstAid2", 0, 260)
check("single player: the page count still decides", last("SurvivalGuide_zombie_attacks_title").locked == true)
PLAYER.pages["Base.BookFirstAid2"] = 260
read("Base.BookFirstAid2", 0, 260)
check("single player: the character's own page count counts too", PLAYER.md.ZeD_Finds and PLAYER.md.ZeD_Finds.medical == true)

-- ---------------------------------------------------------------------------
-- THE LIVE SCHEDULE
-- ---------------------------------------------------------------------------
section("The live schedule (the game's RadioData.xml)")
setPreset(3)
check("RadioData.xml read", CHANNELS and #CHANNELS > 0)
local tvCount, lal = 0, nil
for _, ch in ipairs(CHANNELS or {}) do
    if ch.cat == "Television" then tvCount = tvCount + 1 end
    if ch.GetName() == "Life and Living TV" then lal = ch end
end
check("TV channels found", tvCount >= 5, tvCount)
check("Life and Living's script has broadcasts", lal and lal.script and lal.script.n > 10)
for _, now in ipairs({ 0, 2 * 1440 + 10 * 60, 5 * 1440 + 23 * 60 + 30 }) do
    setRadio(CHANNELS or {}, now)
    local s = F.schedule and F.schedule() or {}
    local today = math.floor(now / 1440)
    local okOrder, okWin, okTv, okTeach = true, true, true, true
    for i, e in ipairs(s) do
        if i > 1 and s[i - 1].at > e.at then okOrder = false end
        if e.at >= (today + 7) * 1440 or e.day < 0 or e.day > 6 then okWin = false end
        local isTv = false
        for _, ch in ipairs(CHANNELS) do if ch.GetName() == e.channel and ch.cat == "Television" then isTv = true end end
        if not isTv then okTv = false end
        if e.teaches == "" then okTeach = false end
    end
    local tag = " (now " .. now .. ")"
    check("shows listed" .. tag, #s > 0, #s)
    check("in time order" .. tag, okOrder)
    check("only the next seven days" .. tag, okWin)
    check("only TV channels" .. tag, okTv)
    check("only shows that teach" .. tag, okTeach)
end
-- what the real data teaches, each named in the game's words
setRadio(CHANNELS or {}, 0)
local all = F.schedule and F.schedule(400) or {}
local text = {}
for _, e in ipairs(all) do text[#text + 1] = e.teaches end
text = table.concat(text, " | ")
check("Fishing taught (FIS+1)", text:find("Fishing", 1, true) ~= nil)
check("Cooking taught (COO+)", text:find("Cooking", 1, true) ~= nil)
check("Carpentry taught (CRP+)", text:find("Carpentry", 1, true) ~= nil)
check("a recipe by its craft recipe's name", text:find("Recipe: Make Fishing Rod", 1, true) ~= nil)
check("no stat codes (BOR, UHP, STS) as teaching", not text:find("BOR", 1, true) and not text:find("UHP", 1, true))
-- a hand-made week: a radio station that teaches, a past show, one beyond the week, one that teaches nothing
local function bc(st, en, codes)
    local lines = {}
    for _, c in ipairs(codes) do lines[#lines + 1] = { getEffectsString = function() return c end } end
    return { getStartStamp = function() return st end, getEndStamp = function() return en end, getLines = function() return jlist(lines) end }
end
local function chan(name, tv, startDay, list)
    local sc = { getStartDayStamp = function() return startDay * 1440 end, getBroadcastList = function() return jlist(list) end }
    return { GetName = function() return name end, IsTv = function() return tv end, getCurrentScript = function() return sc end }
end
local handmade = {
    chan("Life and Living TV", true, 0, {
        bc(1 * 1440 + 6 * 60, 1 * 1440 + 7 * 60, { "FIS+1", "" }),                 -- yesterday: gone
        bc(2 * 1440 + 9 * 60, 2 * 1440 + 11 * 60, { "COO+1", "COO+1, RCP=Make Cake Batter" }),   -- airing now: listed
        bc(2 * 1440 + 18 * 60, 2 * 1440 + 19 * 60, { "BOR-1", "UHP-2" }),           -- teaches nothing
        bc(3 * 1440 + 0, 3 * 1440 + 60, { "CRP+1" }),                               -- tomorrow 00:00
        bc(4 * 1440 + 13 * 60 + 5, 4 * 1440 + 14 * 60, { "FRM+2" }),              -- in 2 days, 1:05 PM
        bc(9 * 1440 + 6 * 60, 9 * 1440 + 7 * 60, { "TRA+1" }),                     -- beyond the week
    }),
    chan("KnoxTalk Radio", false, 0, { bc(2 * 1440 + 12 * 60, 2 * 1440 + 13 * 60, { "FOR+1" }) }),
    chan("Late Start TV", true, 3, { bc(0, 60, { "FOR+1" }) }),                    -- its script starts on day 3
}
setRadio(handmade, 2 * 1440 + 10 * 60)
local s = F.schedule and F.schedule() or {}
check("hand-made: four shows", #s == 4, #s)
check("hand-made: the show airing now first", s[1] and s[1].day == 0 and s[1].mins == 9 * 60 and s[1].teaches == "Cooking, Recipe: Make Cake Batter",
      s[1] and s[1].teaches)
check("hand-made: the radio station left out", not text:find("KnoxTalk", 1, true) and (function()
    for _, e in ipairs(s) do if e.channel == "KnoxTalk Radio" then return false end end
    return true end)())
-- (two shows at the same minute: by channel name, so Late Start TV before Life and Living TV)
check("hand-made: a script's own start day counted", s[2] and s[2].channel == "Late Start TV" and s[2].day == 1 and s[2].mins == 0,
      s[2] and (s[2].channel .. " " .. s[2].day))
check("hand-made: a tie at one minute sorted by channel", s[3] and s[3].channel == "Life and Living TV" and s[3].teaches == "Carpentry")
local tvp = last("SurvivalGuide_television_title")
check("the page: four columns", tvp and #tvp.cols == 4 and tvp.cols[3] == "Channel")
check("the page: Today 09:00", tvp and tvp.rows[1][1] == "Today" and tvp.rows[1][2] == "09:00", tvp and (tvp.rows[1][1] .. " " .. tvp.rows[1][2]))
check("the page: Tomorrow 00:00", tvp and tvp.rows[2][1] == "Tomorrow" and tvp.rows[2][2] == "00:00")
check("the page: In 2 days", tvp and tvp.rows[4] and tvp.rows[4][1] == "In 2 days" and tvp.rows[4][4] == "Farming", tvp and tvp.rows[4] and tvp.rows[4][1])
check("the page: the world's XP cutoff in a note", tvp and tvp.notes[2] == "Shows teach a skill only below level 3 in this world.", tvp and tvp.notes[2])
CLOCK24 = false
tvp = last("SurvivalGuide_television_title")
check("12-hour clock: 9:00 AM", tvp and tvp.rows[1][2] == "9:00 AM", tvp and tvp.rows[1][2])
check("12-hour clock: 12:00 AM at midnight", tvp and tvp.rows[2][2] == "12:00 AM", tvp and tvp.rows[2][2])
check("12-hour clock: 1:05 PM", tvp and tvp.rows[4][2] == "1:05 PM", tvp and tvp.rows[4][2])
CLOCK24 = true
setRadio({ chan("Quiet TV", true, 0, { bc(0, 60, { "BOR-1" }) }) }, 0)
tvp = last("SurvivalGuide_television_title")
check("nothing that teaches on the air: one line saying so", tvp and #tvp.rows == 1 and tvp.rows[1][1] == EN.UI_ZeD_Hidden_TVNone)
-- a server's client: the channels are there (named from the server's data) but no script is loaded
local noScript = function(name) return { GetName = function() return name end, IsTv = function() return true end, getCurrentScript = function() return nil end } end
setRadio({ noScript("Life and Living TV"), noScript("Triple-N") }, 2 * 1440)
tvp = last("SurvivalGuide_television_title")
check("client, no scripts: says the schedule is not available here", tvp and #tvp.rows == 1 and tvp.rows[1][1] == EN.UI_ZeD_Hidden_TVUnavailable,
      tvp and tvp.rows[1] and tvp.rows[1][1])
check("client, no scripts: never says nothing airs", tvp and tvp.rows[1][1] ~= EN.UI_ZeD_Hidden_TVNone)
setRadio({}, 0)
tvp = last("SurvivalGuide_television_title")
check("no channels at all: not available here", tvp and tvp.rows[1][1] == EN.UI_ZeD_Hidden_TVUnavailable)
RADIO = nil
tvp = last("SurvivalGuide_television_title")
check("no radio: not available here, no error", tvp and tvp.rows[1][1] == EN.UI_ZeD_Hidden_TVUnavailable)
-- one channel that fails leaves the others listed
local bad = { GetName = function() error("bad channel") end, IsTv = function() error("bad channel") end }
setRadio({ bad, chan("Life and Living TV", true, 0, { bc(2 * 1440 + 12 * 60, 2 * 1440 + 13 * 60, { "CRP+1" }) }) }, 2 * 1440)
s = F.schedule() or {}
check("a bad channel: the good one still listed", #s == 1 and s[1].teaches == "Carpentry", #s)
-- Build 42's newer skill codes
setRadio({ chan("Life and Living TV", true, 0, {
    bc(2 * 1440 + 60, 2 * 1440 + 120, { "MAS+1, POT+1", "BLA+1", "GLA+1, HUS+1", "BUT+1, TRK+1" }) }) }, 2 * 1440)
s = F.schedule() or {}
check("the newer skill codes named", s[1] and s[1].teaches == "Masonry, Pottery, Blacksmith, Glassmaking, Husbandry, Butchering, Tracking",
      s[1] and s[1].teaches)

-- ---------------------------------------------------------------------------
-- THE ODDS
-- ---------------------------------------------------------------------------
section("The infection odds by Transmission")
local want = {
    [1] = { "Always", "Sometimes", "Sometimes" }, [2] = { "Always", "Never", "Never" },
    [3] = { "Always", "Sometimes", "Sometimes" }, [4] = { "Never", "Never", "Never" },
}
for t = 1, 4 do
    TRANSMISSION = t
    local p = last("SurvivalGuide_zombie_attacks_title")
    local got = p and { p.rows[1][2], p.rows[2][2], p.rows[3][2] } or {}
    check("Transmission " .. t .. ": bite, laceration, scratch", got[1] == want[t][1] and got[2] == want[t][2] and got[3] == want[t][3],
          table.concat(got, ","))
    check("Transmission " .. t .. ": the world's choice in the note", p and p.notes[1] == "Transmission in this world: " .. TLABELS[t] .. ".", p and p.notes[1])
end
local p = last("SurvivalGuide_zombie_attacks_title")
check("the wounds in the game's words", p and p.rows[1][1] == "Bitten" and p.rows[2][1] == "Laceration" and p.rows[3][1] == "Scratched")
check("behind the spoiler bar, as the world's table", p and p.spoiler == true)
check("Mortality not Never: no not-fatal note", p and p.notes[1] ~= nil and not p.notes[1]:find("not fatal", 1, true))
MORTALITY = 7
TRANSMISSION = 1
p = last("SurvivalGuide_zombie_attacks_title")
check("Mortality Never: says plainly it is not fatal, first", p and p.notes[1] == "The infection is not fatal in this world (Infection Mortality: Never).",
      p and p.notes[1])
check("Mortality Never: a bite still reads Always, with that note", p and p.rows[1][2] == "Always")
MORTALITY = 5
check("never the character's body: no BodyDamage read", not (readFile(LUA .. "client/ZeD/ZeD_HiddenFacts.lua") or ""):find("getBodyDamage", 1, true))

-- ---------------------------------------------------------------------------
-- RECIPE SOURCES
-- ---------------------------------------------------------------------------
section("Recipe sources")
setPreset(1)
check("Vanilla: the card keeps its words", F.recipeSourceText("MakeFishingRod") == nil)
setPreset(2)
check("Vanilla Plus: the card keeps its words", F.recipeSourceText("MakeFishingRod") == nil)
setPreset(3)
check("Vanilla Access: names the magazine", F.recipeSourceText("Forge_Tongs") == "Find Smithing Vol. 1", F.recipeSourceText("Forge_Tongs"))
check("Vanilla Access: two magazines named", F.recipeSourceText("MakeFishingRod") == "Find Angler USA Magazine Vol. 1, Angler USA Magazine Vol. 2",
      F.recipeSourceText("MakeFishingRod"))
check("Vanilla Access: a recipe no magazine teaches keeps the card's words", F.recipeSourceText("MakeSandwich") == nil)
check("a group (base:kitchentools) resolves to its recipes", F.recipeSourceText("Forge_Saucepan") == "Find Smithing Vol. 2",
      F.recipeSourceText("Forge_Saucepan"))
check("a group with no members: its recipes keep the card's words", F.recipeSourceText("Forge_Tongs") == "Find Smithing Vol. 1")
F._recipeIdx = nil
ITEMS_FAIL = 1
check("a build that fails: the card's words", F.recipeSourceText("Forge_Tongs") == nil)
check("... and the next card tries again", F.recipeSourceText("Forge_Tongs") == "Find Smithing Vol. 1")
local cc = readFile(LUA .. "client/ZeD/CraftingCore.lua") or ""
check("the crafting card asks for it", cc:find("ZeD.Finds.recipeSourceText(entry.name)", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
-- THE WORDS IN EVERY LANGUAGE
-- ---------------------------------------------------------------------------
section("Keys in all 28 languages")
local src = (readFile(LUA .. "client/ZeD/ZeD_HiddenFacts.lua") or "") .. (readFile(LUA .. "client/ZeD/Settings.lua") or "")
local used = {}
for k in src:gmatch('"(UI_ZeD_Hidden_[%w_]+)"') do used[k] = true end
for k in src:gmatch('"(UI_ZeD_Settings_HiddenFacts[%w_]*)"') do used[k] = true end
used.UI_ZeD_Settings_FindFirst = true
used.UI_ZeD_Craft_FindNamed = true
for k in pairs(asked) do if k:find("^UI_ZeD_Hidden_") then used[k] = true end end
local n = 0
for k in pairs(used) do
    n = n + 1
    local enMarks = {}
    for d in (EN[k] or ""):gmatch("%%(%d)") do enMarks[d] = true end
    for _, l in ipairs(LANGS) do
        local v = UI[l] and UI[l][k]
        check(l .. " has " .. k, v ~= nil and v ~= "")
        if v then
            for d in pairs(enMarks) do check(l .. " " .. k .. " keeps %" .. d, v:find("%" .. d, 1, true) ~= nil) end
            check(l .. " " .. k .. ": no middle dot", not v:find("\194\183", 1, true))
        end
    end
end
check("keys counted", n >= 26, n)

require = realRequire
print(string.format("hidden_facts_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
