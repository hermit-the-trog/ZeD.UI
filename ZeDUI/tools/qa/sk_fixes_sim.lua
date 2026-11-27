-- ZeDUI/tools/qa/sk_fixes_sim.lua (Nov 27 2026): the Skills tab's fixes from QA's skills map
-- (ZeDUI/qa/audits/2026-11-27_map_skills_info.md), checked with no game running. The real SkillsTab.lua and
-- ZeD_Pins.lua run against stubs of the game's perks, skill books, sandbox and player. Checks:
--   S15  a skill pin is kept by the perk's id; under another language its name is the one shown; a pin saved by an
--        English name moves to the id, a stale one is dropped and no longer counts toward the three
--   S23  a book whose last level is at most the skill level + 1 shows as read (ISLiteratureUI.lua:91)
--   S24  sandbox MetaKnowledge 3 lists only the books the game counts known (ISLiteratureUI.lua:78, 124)
--   S25  a title keeps no numeral of its own before the Vol.; volumes follow the books' LvlSkillTrained
--   S27  the Character window's skill row right-click and training row click test the scroll view (source read)
-- Run from the repo root:  lua.exe ZeDUI/tools/qa/sk_fixes_sim.lua   (prints FAIL lines and a last summary line)
-- An optional first argument is a folder to load the mod's Lua from instead (an older copy, to see the checks fail).

local ROOT = (arg and arg[1]) or string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]sk_fixes_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             contains = function(_, v) for _, x in ipairs(t) do if x == v then return true end end; return false end }
end
require = function() return nil end
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function() end, Remove = function() end }
    rawset(t, k, e)
    return e
end })
function getTimestampMs() return 100000 end
function getText(k) return k end
function getPreviousXpLvl() return 0 end
ItemType = { LITERATURE = "Literature" }

-- the game's perks, their names in the language the game runs in
local LANG = "EN"
local NAMES = {
    EN = { Woodwork = "Carpentry", Cooking = "Cooking", Fitness = "Fitness", Farming = "Agriculture", Trapping = "Trapping" },
    DE = { Woodwork = "Tischlerei", Cooking = "Kochen", Fitness = "Fitness", Farming = "Landwirtschaft", Trapping = "Fallenstellen" },
}
Perks = { None = { isNone = true } }
local PERKS = {}
for _, id in ipairs({ "Woodwork", "Cooking", "Fitness", "Farming", "Trapping" }) do
    local perk = {}
    perk.getId = function() return id end
    perk.getName = function() return NAMES[LANG][id] end
    perk.getType = function() return perk end
    perk.getParent = function() return "Crafting" end
    perk.getXpForLevel = function() return 100 end
    Perks[id] = perk
    PERKS[#PERKS + 1] = perk
end
PerkFactory = { PerkList = jlist(PERKS), getPerk = function(p) return p end }
SkillBook = { Carpentry = { perk = Perks.Woodwork }, Farming = { perk = Perks.Farming }, Trapping = { perk = Perks.Trapping } }

-- the skill books (script items), each with its level range as the game's scripts give it
local function book(skill, n, title, lvl)
    return {
        isItemType = function(_, t) return t == ItemType.LITERATURE end,
        getSkillTrained = function() return skill end,
        getDisplayName = function() return title end,
        getFullName = function() return "Base.Book" .. skill .. n end,
        getNumberOfPages = function() return 200 end,
        getLevelSkillTrained = function() return lvl end,
        getMaxLevelTrained = function() return lvl + 2 end,
    }
end
local ITEMS = {
    book("Carpentry", 1, "Carpentry I: \"A Guide to Nailing\"", 1),
    book("Carpentry", 2, "Carpentry II: \"Carpentry, Woodcraft Style\"", 3),
    book("Carpentry", 3, "Carpentry III: \"Hand Crafted Shelving and Storage\"", 5),
    book("Carpentry", 4, "Carpentry IV: \"Making Your Own Cabin From Scratch\"", 7),
    book("Carpentry", 5, "Carpentry V: \"Site Joinery and Architectural Carpentry\"", 9),
    book("Farming", 1, "Agriculture I: \"Better Gardening\"", 1),
    book("Farming", 2, "Agriculture II: \"Growing Food at Home\"", 3),
    -- (titles whose alphabet runs against their levels: the volumes must follow the levels)
    book("Trapping", 1, "Zebra Snares for Beginners", 1),
    book("Trapping", 2, "Advanced Pest Control", 3),
}
function getScriptManager() return { getAllItems = function() return jlist(ITEMS) end } end

local META = 2
function getSandboxOptions()
    return { getOptionByName = function(_, n)
        if n == "MetaKnowledge" then return { getValue = function() return META end } end
        return nil
    end }
end

-- the player
local LEVEL, READ = {}, {}
local MD = {}
local PLAYER = {
    getModData = function() return MD end,
    getPlayerNum = function() return 0 end,
    getPerkLevel = function(_, perk) return LEVEL[perk] or 0 end,
    getXp = function() return { getXP = function() return 40 end, getPerkBoost = function() return 0 end } end,
    getAlreadyReadPages = function(_, ft) return READ[ft] or 0 end,
    getAlreadyReadBook = function() return jlist({}) end,
    getInventory = function() return { getItems = function() return jlist({}) end } end,
}
function getSpecificPlayer() return PLAYER end
function instanceof() return false end

local COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local function freshZeD()
    ZeD = {
        T = setmetatable({ px = function(n) return n end, sp = { xs = 3 } }, { __index = function() return COLOR end }),
        tr = function(k, ...)
            local a = { ... }
            local s = k
            for i = 1, #a do s = s .. ":" .. tostring(a[i]) end
            return s
        end,
        upper = string.upper,
        textCase = function(s) return s end,
        Safe = { on = function() return false end },
    }
    _G._zedPinsHooked = true
end

-- a game started in a language: the mod's files loaded fresh, as at a restart
local function start(lang)
    LANG = lang
    freshZeD()
    dofile(CLIENT .. "SkillsTab.lua")
    dofile(CLIENT .. "ZeD_Pins.lua")
    return ZeD.Pins, ZeD.SkillsTab
end

-- ---------------------------------------------------------------------------
-- S15: pins by the perk's id
-- ---------------------------------------------------------------------------
local P, SK = start("EN")
P.toggle(PLAYER, "skill", "Carpentry", "Carpentry")
local L = MD.ZeD_Pins or {}
check("S15 a skill pin made in English is kept by the perk's id", L[1] and L[1].id == "Woodwork", L[1] and L[1].id)

P, SK = start("DE")
local stats = P.stats(PLAYER)
check("S15 the pin shows after a restart in German", #stats == 1 and string.find(stats[1].text, "Tischlerei", 1, true) ~= nil,
    stats[1] and stats[1].text)
local names = P.skillNames(PLAYER)
check("S15 the row mark has the name German shows", names[1] == "Tischlerei", names[1])
check("S15 the German name finds the pin", P.isPinned(PLAYER, "skill", "Tischlerei"))
P.toggle(PLAYER, "skill", "Tischlerei")
check("S15 the German name unpins it", #(MD.ZeD_Pins or {}) == 0, #(MD.ZeD_Pins or {}))

-- pins saved by name before: an English one, one in this language, one that matches nothing here
MD.ZeD_Pins = { { k = "skill", id = "Carpentry" }, { k = "skill", id = "Tischlerei (old)" }, { k = "skill", id = "Kochen" } }
stats = P.stats(PLAYER)
L = MD.ZeD_Pins
check("S15 a stale pin no longer counts: every pin counted is shown", #L == #stats, #stats .. " shown of " .. #L .. " counted")
check("S15 an English name moves to its perk's id", L[1] and L[1].id == "Woodwork", L[1] and L[1].id)
check("S15 a name in this language moves to its perk's id", L[2] and L[2].id == "Cooking", L[2] and L[2].id)
check("S15 the stale pin is dropped", #L == 2, #L)

-- ---------------------------------------------------------------------------
-- S25: titles and volumes
-- ---------------------------------------------------------------------------
P, SK = start("EN")
local function group(groups, label)
    for _, g in ipairs(groups) do if g.label == label then return g end end
    return nil
end
local groups = SK.gatherTrainingData(PLAYER)
local farm = group(groups, "Farming")
local doubled = {}
for _, g in ipairs(groups) do
    for _, it in ipairs(g.items) do
        if string.find(it.title, "%s[IVX]+:") then doubled[#doubled + 1] = it.title end
    end
end
check("S25 no title keeps its own numeral before the Vol.", #doubled == 0, table.concat(doubled, "; "))
check("S25 Agriculture I's title is the quoted name", farm and farm.items[1] and farm.items[1].title == "\"Better Gardening\"",
    farm and farm.items[1] and farm.items[1].title)
local trap = group(groups, "Trapping")
local zebra = nil
for _, it in ipairs(trap and trap.items or {}) do if string.find(it.title, "Zebra", 1, true) then zebra = it end end
check("S25 volumes follow LvlSkillTrained, not the alphabet", zebra and zebra.volume == "I", zebra and zebra.volume)

-- ---------------------------------------------------------------------------
-- S23: known by level
-- ---------------------------------------------------------------------------
LEVEL[Perks.Woodwork] = 10
groups = SK.gatherTrainingData(PLAYER)
local carp = group(groups, "Carpentry")
local notRead = {}
for _, it in ipairs(carp and carp.items or {}) do if it.status ~= "read" then notRead[#notRead + 1] = it.title .. " " .. it.status end end
check("S23 Carpentry 10 with none read: all five books known", carp and #carp.items == 5 and #notRead == 0, table.concat(notRead, "; "))
LEVEL[Perks.Woodwork] = 2
groups = SK.gatherTrainingData(PLAYER)
carp = group(groups, "Carpentry")
local st = {}
for _, it in ipairs(carp and carp.items or {}) do st[#st + 1] = it.status end
check("S23 Carpentry 2: volume I known (max 3), volume II not (max 5)", st[1] == "read" and st[2] == "missing", table.concat(st, ","))

-- ---------------------------------------------------------------------------
-- S24: MetaKnowledge 3
-- ---------------------------------------------------------------------------
META = 3
LEVEL[Perks.Woodwork] = 0
READ["Base.BookCarpentry3"] = 200
groups = SK.gatherTrainingData(PLAYER)
carp = group(groups, "Carpentry")
check("S24 MetaKnowledge 3: only the read Carpentry book is listed", carp and #carp.items == 1 and carp.items[1].status == "read",
    carp and #carp.items)
check("S24 MetaKnowledge 3: a skill with no known book has no row", group(groups, "Farming") == nil)
META = 2
groups = SK.gatherTrainingData(PLAYER)
carp = group(groups, "Carpentry")
check("S24 MetaKnowledge 2: every Carpentry book listed", carp and #carp.items == 5, carp and #carp.items)

-- ---------------------------------------------------------------------------
-- S27: the Character window's clicks test the scroll view (the handlers are closures in the window: read the source)
-- ---------------------------------------------------------------------------
local f = io.open(CLIENT .. "ZeD_CharacterWindow.lua", "rb")
local src = f and f:read("*a") or ""
if f then f:close() end
local function block(startPat, len)
    local a = string.find(src, startPat, 1, true)
    return a and string.sub(src, a, a + len) or ""
end
local rc = block("drawer.onRightMouseUp = function", 900)
check("S27 the skill row right-click tests the scroll view", string.find(rc, "_skillsHoverView", 1, true) ~= nil)
local tc = block("if win._activeTab == \"skills\" and win._trainingGroupZones then", 700)
check("S27 the training row click tests the scroll view", string.find(tc, "_skillsHoverView", 1, true) ~= nil)

print("sk_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
