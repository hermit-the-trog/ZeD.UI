-- ZeDUI/tools/qa/drawer_tabs_perf_sim.lua  (Nov 8 2026, Build; punch list 120): the Character window's four heavy
-- drawer tabs (Equipment with the list and the doll, Thermal, Identity, Skills) drawn frame after frame with no
-- game running, before and after the drawing-cost work.
--   * Loads the real Scale, Tokens, Tr, Atoms, AtomExtensions, Molecules, ZeD_BodyFigure, ProtectionTab, EquipDoll
--     and the four tabs twice, each into its own sandbox on the same stubs: as they are in BASE and as they are in
--     the checkout. BASE is a revision (origin/main, to check a change against main) or a folder holding those
--     files; with none, the checkout alone: every frame drawn, counted and printed, nothing compared (so a sim
--     loop that gives no argument passes).
--   * A stand-in player (worn clothes, a stocked inventory, 40 skills, traits, a thermoregulator), a stand-in
--     TextManager whose widths add up letter by letter, and a panel that writes down every draw (its Java element's
--     too), every surface strip's claim on the window body, and the help line's words.
--   * Plays the same frames into both (16 ms apart; the pointer away, then down the card over the bars and rows)
--     and compares them: the help lines in their order, and the draws word for word; where a frame's draws differ
--     (a chevron or a dashed edge drawn from the line textures instead of rect by rect) every draw but the thin
--     ones must still match one for one, and sampled frames are painted both ways, pixel by pixel (rects, and the
--     line textures' own pixels from linetex_pixels.lua), and must come out the same, but for the framed fill
--     bars' cells: there the same cells in the same colours, the middle ones equal and each within a pixel of its
--     old width, the end ones wider by the leftover split between them, meeting the frame. Also at the half card, in
--     Simple, with the full photo, the figure folded, another view, a window's own colours.
--   * Counts per frame, old against new: Lua instructions (a count hook), the engine's text measures, wrap and
--     truncate calls, Java calls on the stand-ins (each draw is one), draws, and the Lua memory a frame allocates
--     (GC stopped). Fails when the new draws, Java calls or memory a frame are more than the base's.
--   * With -prof, prints where the instructions, the Java calls and the draws go, by function, for the checkout.
-- Run from the repo root:
--   lua51 ZeDUI/tools/qa/drawer_tabs_perf_sim.lua [origin/main | <rev> | <dir>] [-prof]
-- It prints FAIL lines, the numbers, and a last line "drawer_tabs_perf_sim: N checks, M failed", and exits 1 if any
-- failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]drawer_tabs_perf_sim%.lua$", "")
local BASE, PROF = nil, false   -- (no base given: the checkout alone, see below)
LINEPROF = os.getenv("LINEPROF") ~= nil   -- (-prof by line, not by function)
for _, a in ipairs(arg or {}) do
    if a == "-prof" then PROF = true else BASE = a end
end

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        if failed <= 40 then print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
    end
end
local function section(s) print("-- " .. s) end
local function noop() end

local function readFile(path)
    local f = io.open(ROOT .. path, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return s
end
local function gitShow(path)
    local f = io.open(BASE .. "/" .. path, "rb")   -- (BASE a folder: its files)
    if f then local s = f:read("*a"); f:close(); return s end
    local h = io.popen("git " .. (ROOT ~= "" and ('-C "' .. ROOT .. '" ') or "") .. "show " .. BASE .. ":" .. path .. " 2>nul")
    if not h then return nil end
    local s = h:read("*a"); h:close()
    if s == "" then return nil end
    return s
end

local FILES = {
    "42/media/lua/shared/ZeD/Scale.lua",      -- (the game loads shared/ZeD by name: Scale before Tokens)
    "42/media/lua/shared/ZeD/Tokens.lua",
    "42/media/lua/shared/ZeD/Tr.lua",
    "42/media/lua/client/ZeD/Atoms.lua",
    "42/media/lua/client/ZeD/AtomExtensions.lua",
    "42/media/lua/client/ZeD/Molecules.lua",
    "42/media/lua/client/ZeD/ZeD_BodyFigure.lua",
    "42/media/lua/client/ZeD/ProtectionTab.lua",
    "42/media/lua/client/ZeD/EquipDoll.lua",
    "42/media/lua/client/ZeD/EquipmentTab.lua",
    "42/media/lua/client/ZeD/ZeD_TabFill.lua",   -- (the fill blocks under the Thermal grid)
    "42/media/lua/client/ZeD/ThermalTab.lua",
    "42/media/lua/client/ZeD/IdentityTab.lua",
    "42/media/lua/client/ZeD/SkillsTab.lua",
}

-- ===========================================================================
-- THE COUNTERS (one set; each world points the stubs at its own)
-- ===========================================================================
local C = nil
local function newCounts()
    return { java = 0, draw = 0, measure = 0, wrap = 0, trunc = 0, byJava = {} }
end
local function jcount(name)
    if C then
        C.java = C.java + 1
        C.byJava[name] = (C.byJava[name] or 0) + 1
    end
end

-- a Java object: each method a counted call; a method it lacks is an error naming it
local function J(name, methods)
    local o = { __name = name }
    return setmetatable(o, {
        __index = function(t, k)
            local m = methods[k]
            if m == nil then
                if k == "__name" then return nil end
                error("stand-in " .. name .. " has no " .. tostring(k), 2)
            end
            local f
            if type(m) == "function" then
                f = function(self, ...) jcount(k); return m(self, ...) end
            else
                f = function() jcount(k); return m end
            end
            rawset(t, k, f)
            return f
        end,
        __tostring = function() return name end,
    })
end
-- a Java list (0-based get, size)
local function JList(items, name)
    return J(name or "ArrayList", {
        size = function() return #items end,
        get = function(_, i) return items[i + 1] end,
        isEmpty = function() return #items == 0 end,
        contains = function(_, v) for _, x in ipairs(items) do if x == v then return true end end; return false end,
    })
end

-- ===========================================================================
-- THE WORLD: a stand-in player, textures, the clock
-- ===========================================================================
local clock = { ms = 1700000000000 }

local texCache = {}
local function tex(path)
    local t = texCache[path]
    if not t then
        t = J("Texture:" .. tostring(path), {
            getWidth = 32, getHeight = 32, getWidthOrig = 32, getHeightOrig = 32, getName = tostring(path),
            isReady = true, getXStart = 0, getYStart = 0, getXEnd = 1, getYEnd = 1,
        })
        texCache[path] = t
    end
    return t
end

local function color(r, g, b)
    return J("Color", { getRedFloat = r, getGreenFloat = g, getBlueFloat = b, getR = r, getG = g, getB = b, getA = 1 })
end

local PARTS = { "Hand_L", "Hand_R", "ForeArm_L", "ForeArm_R", "UpperArm_L", "UpperArm_R", "Torso_Upper", "Torso_Lower",
    "Head", "Neck", "Groin", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }
local partEnum = {}
for i, p in ipairs(PARTS) do
    partEnum[p] = J("BodyPartType:" .. p, { toString = p, index = i - 1, name = p })
    getmetatable(partEnum[p]).__tostring = function() return p end
end

local function makeItem(i, opts)
    opts = opts or {}
    local name = opts.name or ("Thing number " .. i)
    local covered = {}
    for _, p in ipairs(opts.parts or {}) do covered[#covered + 1] = partEnum[p] end
    return J("Item:" .. name, {
        getDisplayName = name, getName = name, getFullType = "Base.Thing" .. i, getType = "Thing" .. i,
        getTex = tex("Item_" .. i), getTexture = tex("Item_" .. i), getIcon = tex("Item_" .. i),
        getCondition = opts.cond or 7, getConditionMax = 10, isBroken = false,
        isEquipped = opts.worn == true, getCoveredParts = JList(covered),
        getDefForPart = function(_, part, bite, bullet) return bite and 40 or (bullet and 10 or 25) end,
        getBloodClothingType = nil, getHolesNumber = 0, getPatchesNumber = 0, getAttachedSlot = -1,
        getWetness = 0, getDirtyness = 0, getBloodlevel = 0, getBiteDefense = 30, getScratchDefense = 20,
        getBulletDefense = 0, getInsulation = 0.4, getWindresistance = 0.3, getWaterResistance = 0.2,
        getActualWeight = 0.5, getUnequippedWeight = 0.5, getEquippedWeight = 0.3, getWeight = 0.5,
        getCategory = opts.worn and "Clothing" or "Item", IsClothing = opts.worn == true, isClothing = opts.worn == true,
        getBodyLocation = opts.loc, getItemReplacementPrimaryHand = nil, getModData = {},
        getID = 1000 + i, getScriptItem = J("ScriptItem", { getAttachmentType = nil }),
        getAttachmentType = nil, isHidden = false, getVisual = nil, getClothingItem = nil,
        getMaxHitCount = 0, getCount = 1,
    })
end

-- the worn clothes (location -> covered parts), then hands
local WORN = {
    { "base:hat", "Baseball cap", { "Head" } },
    { "base:tshirt", "T-shirt", { "Torso_Upper", "Torso_Lower" } },
    { "base:jacket", "Leather jacket", { "Torso_Upper", "Torso_Lower", "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R" } },
    { "base:pants", "Jeans", { "Groin", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R" } },
    { "base:socks", "Socks", { "Foot_L", "Foot_R" } },
    { "base:shoes", "Army boots", { "Foot_L", "Foot_R" } },
    { "base:hands", "Leather gloves", { "Hand_L", "Hand_R" } },
    { "base:belt", "Belt", {} },
    { "base:underwearbottom", "Briefs", { "Groin" } },
    { "base:eyes", "Glasses", {} },
    { "base:wristwatch_left", "Digital watch", {} },
    { "base:neck", "Scarf", { "Neck" } },
}

local function buildPlayer()
    local items, worn = {}, {}
    for i, w in ipairs(WORN) do
        local it = makeItem(i, { name = w[2], worn = true, parts = w[3], loc = w[1] })
        items[#items + 1] = it
        worn[#worn + 1] = J("WornItem", { getItem = it, getLocation = w[1] })
    end
    local primary = makeItem(50, { name = "Baseball bat" })
    items[#items + 1] = primary
    for i = 1, 140 do items[#items + 1] = makeItem(100 + i) end
    local inv = J("ItemContainer", { getItems = JList(items), getItemsFromCategory = JList({}), getCapacityWeight = 10 })

    -- perks: 8 parents, 5 skills each
    local perks, perkList = {}, {}
    local PARENTS = { "Combat", "Firearm", "Crafting", "Survivalist", "Agility", "Passiv", "Farming", "Melee" }
    local SKN = { "Axe", "Long Blunt", "Short Blunt", "Long Blade", "Short Blade", "Aiming", "Reloading", "Carpentry",
        "Cooking", "Electrical", "Metalworking", "Tailoring", "Mechanics", "First Aid", "Fishing", "Foraging", "Trapping",
        "Sprinting", "Lightfooted", "Nimble", "Sneaking", "Fitness", "Strength", "Agriculture", "Animal Care",
        "Butchering", "Spear", "Maintenance", "Pottery", "Masonry", "Glassmaking", "Blacksmith", "Knapping",
        "Carving", "Tracking", "Combat Readiness", "Swimming", "Woodcutting", "Nimble Hands", "Long Arms" }
    local parentObjs = {}
    local NONE = J("Perk:None", { getName = "None" })
    for pi, pn in ipairs(PARENTS) do
        parentObjs[pi] = J("Perk:" .. pn, { getName = pn, isPassiv = pn == "Passiv", getType = nil })
        parentObjs[pi].__name = nil
    end
    local levels, xp = {}, {}
    for i, n in ipairs(SKN) do
        local par = parentObjs[((i - 1) % #PARENTS) + 1]
        local p = J("Perk:" .. n, {
            getName = n, getParent = par, getType = n, isPassiv = false,
            getXp1 = 75, getXp2 = 150, getXp3 = 300, getXp4 = 750, getXp5 = 1500, getXp6 = 3000, getXp7 = 4500,
            getXp8 = 6000, getXp9 = 7500, getXp10 = 9000,
            getXpForLevel = function(_, l) return 75 * l end,
        })
        perks[n] = p
        perkList[#perkList + 1] = p
        levels[n] = (i * 3) % 11
        xp[n] = (i * 37) % 900
    end
    local perkParent = {}
    for pi, par in ipairs(parentObjs) do perkParent[par] = par end
    _G.__PERKS = { list = perkList, parentOf = function(t) return perkParent[t] end, NONE = NONE }

    local xpObj = J("XP", {
        getXP = function(_, t) return xp[t] or 0 end,
        getPerkBoost = function(_, t) return (#t % 4 == 0) and 2 or 0 end,
    })

    -- the thermoregulator: a node per part, every getter there is
    local nodes = {}
    local function node(i)
        local m = {}
        for _, g in ipairs({ "getSkinCelcius", "getSkinSurface", "getHeatDelta", "getPrimaryDelta", "getSecondaryDelta",
                             "getInsulation", "getWindresist", "getBodyWetness", "getClothingWetness",
                             "getBodyResponse", "getDistToCore" }) do
            local v = ((i * 7 + #g) % 10) / 10
            m[g] = (g == "getSkinCelcius") and (33 + v * 3) or v
            m[g .. "UI"] = v
        end
        return J("ThermalNode", m)
    end
    local thermo = J("Thermoregulator", {
        getCoreCelcius = 37.1, getTemperatureAir = 21.5, getTemperatureAirAndWind = 18.2, getHeatGenerationUI = 0.22,
        getNodeForType = function(_, bp)
            local k = tostring(bp)
            if not nodes[k] then nodes[k] = node(#k) end
            return nodes[k]
        end,
    })
    local bd = J("BodyDamage", { getThermoregulator = thermo })
    local visual = J("HumanVisual", {
        getHairColor = color(0.4, 0.3, 0.2), getHairModel = "Short", getBeardModel = "Goatee", getBodyHairIndex = 2,
        getSkinTextureIndex = 1,
    })
    local nutrition = J("Nutrition", { getWeight = 80.4, isIncWeightLot = false, isIncWeight = true, isDecWeight = false })
    local prof = J("Profession", { toString = "base:carpenter", getName = "carpenter" })
    local desc = J("SurvivorDesc", {
        getSurname = "Fossoil", getForename = "Jim", getCharacterProfession = prof, isFemale = false,
    })
    local traits = {}
    for _, t in ipairs({ "Strong", "Fast Learner", "Outdoorsman", "Smoker", "Clumsy", "Pacifist", "Organized", "Brave",
                         "Thin-skinned", "Insomniac" }) do traits[#traits + 1] = t end
    local charTraits = J("CharacterTraits", { getKnownTraits = JList(traits) })
    local modData = { ["Fav:Baseball Bat"] = 12, ["Fav:Axe"] = 3 }
    for i = 1, 60 do modData["mod" .. i] = i end
    local readBooks = JList({})

    local p = J("IsoPlayer", {
        getInventory = inv, getWornItems = JList(worn, "WornItems"),
        getPrimaryHandItem = primary, getSecondaryHandItem = primary, isFemale = false,
        getPerkLevel = function(_, t) return levels[t] or 0 end, getXp = xpObj,
        getBodyDamage = bd, getHumanVisual = visual, getNutrition = nutrition, getDescriptor = desc,
        getCharacterTraits = charTraits, getModData = modData, getTimeSurvived = "3 days, 4 hours, 12 minutes",
        getAlreadyReadPages = function(_, n) return (#n % 5 == 0) and 3 or 0 end, getAlreadyReadBook = readBooks,
        getPlayerNum = 0, getDisplayName = "Jim Fossoil", getUsername = "jim", getZombieKills = 41,
        isDead = false, getVehicle = nil, getClothingWetness = 0,
    })
    return p
end

-- ===========================================================================
-- THE PANEL: every draw written down
-- ===========================================================================
local function fmt(v)
    local tv = type(v)
    if tv == "number" then
        if v == math.floor(v) then return tostring(v) end
        return string.format("%.5f", v)
    end
    if tv == "table" then return tostring(rawget(v, "__name") or "t") end
    return tostring(v)
end
local function newPanel(world)
    local P = { x = 0, y = 0, width = 900, height = 1600, mx = -500, my = -500, __name = "panel" }
    local log
    -- the panel's Java element (the license's pattern draws on it straight): its calls go in the log too
    P.javaObject = setmetatable({ __name = "javaObject" }, { __index = function(t, k)
        local kind = "jo:" .. k
        local f = function(self, ...) log(kind, ...) end
        rawset(t, k, f)
        return f
    end })
    log = function(kind, ...)
        C.draw = C.draw + 1
        jcount(kind)
        if C.byCaller then
            -- (-prof: which function asked for the draw)
            local info = debug.getinfo(3, "S")
            local k = info and (info.short_src .. ":" .. tostring(info.linedefined)) or "?"
            C.byCaller[k] = (C.byCaller[k] or 0) + 1
        end
        if world.nolog then return end   -- (the counting runs: the memory is the tab's alone)
        local n = select("#", ...)
        local parts = { kind }
        for i = 1, n do parts[i + 1] = fmt((select(i, ...))) end
        world.frame[#world.frame + 1] = table.concat(parts, " ")
        world.cmds[#world.cmds + 1] = { kind, n, ... }   -- (the same draw, for painting)
    end
    -- (made once: a field the panel lacks, isCollapsed, is asked every draw, and must cost the tab nothing here)
    local fixed = {
        getMouseX = function(self) return self.mx end, getMouseY = function(self) return self.my end,
        getAbsoluteX = function() return 100 end, getAbsoluteY = function() return 50 end,
        getX = function(self) return self.x end, getY = function(self) return self.y end,
        getWidth = function(self) return self.width end, getHeight = function(self) return self.height end,
        isMouseOver = function(self) return self.mx >= 0 end, addChild = noop, removeChild = noop,
        isVisible = function() return true end, getIsVisible = function() return true end,
    }
    return setmetatable(P, { __index = function(t, k)
        -- (string.find, not string.sub: a field asked every draw, isCollapsed, must not make a string each time)
        if type(k) == "string" and (string.find(k, "draw", 1, true) == 1 or k == "setStencilRect" or k == "clearStencilRect"
                or k == "repaintStencilRect" or k == "suspendStencil" or k == "resumeStencil") then
            local f = function(self, ...) log(k, ...) end
            rawset(t, k, f)
            return f
        end
        if fixed[k] then rawset(t, k, fixed[k]); return fixed[k] end
        return nil
    end })
end

local function newScroll()
    return {
        scrollPos = 0, visible = false, x = 0, y = 0, height = 0,
        setBarSize = function(self, v) self.bar = v end,
        setScrollPos = function(self, v) self.scrollPos = math.max(0, math.min(1, v)) end,
        draw = function(self, panel) panel:drawRect(self.x, self.y, 8, self.height, 1, 0.5, 0.5, 0.5) end,
    }
end

-- ===========================================================================
-- THE SANDBOX: one tree of files on the stubs
-- ===========================================================================
local function newWorld(label, getSrc)
    local world = { label = label, frame = {}, counts = newCounts() }
    local env = {}
    world.env = env
    local G = _G
    -- the engine's TextManager: every letter its own width, whole numbers
    local realTM = {
        MeasureStringX = function(_, font, s)
            C.measure = C.measure + 1; jcount("MeasureStringX")
            s = tostring(s)
            local w = 0
            for i = 1, #s do w = w + 4 + (string.byte(s, i) % 5) end
            return w
        end,
        MeasureStringY = function(_, font, s) C.measure = C.measure + 1; jcount("MeasureStringY"); return 16 end,
        getFontHeight = function() jcount("getFontHeight"); return 16 end,
        getFontFromEnum = function() return nil end,
    }
    local core = J("Core", {
        getScreenWidth = 3840, getScreenHeight = 2160, getOptionFontSize = 2, getOptionFontSizeReal = 2,
        getOptionUIRenderFPS = 60, getGoodHighlitedColor = color(0, 1, 0), getBadHighlitedColor = color(1, 0, 0),
        isDedicated = false, getOptionTemperatureDisplayCelsius = true, getOptionDisplayAsCelsius = true,
        getDebug = false, getOptionMoodleSize = 2, getOptionTooltipFont = "Small",
    })
    local fontNames = { "Small", "Medium", "Large", "Massive", "MainMenu1", "MainMenu2", "Cred1", "Cred2", "NewSmall",
        "NewMedium", "NewLarge", "Code", "CodeSmall", "CodeMedium", "CodeLarge", "MediumNew", "AutoNormSmall",
        "AutoNormMedium", "AutoNormLarge", "Dialogue", "Intro", "Handwritten", "DebugConsole", "Title", "SdfRegular",
        "SdfBold", "SdfItalic", "SdfBoldItalic", "SdfOldRegular", "SdfOldBold", "SdfOldItalic", "SdfOldBoldItalic",
        "SdfRobertoSans", "SdfCaveat" }
    local UIFont = {}
    for _, n in ipairs(fontNames) do UIFont[n] = setmetatable({ __name = "UIFont." .. n }, { __tostring = function() return "UIFont." .. n end }) end
    UIFont.FromString = function(s) return UIFont[s] end

    local base = {
        print = noop, require = noop, tostring = tostring, tonumber = tonumber, type = type, pairs = pairs, ipairs = ipairs,
        select = select, unpack = unpack, pcall = pcall, error = error, assert = assert, setmetatable = setmetatable,
        getmetatable = getmetatable, rawget = rawget, rawset = rawset, rawequal = rawequal, next = next,
        string = string, table = table, math = math, os = { time = os.time, date = os.date, clock = os.clock },
        loadstring = loadstring, xpcall = xpcall,
        UIFont = UIFont,
        getTimestampMs = function() return clock.ms end,
        getTimestamp = function() return math.floor(clock.ms / 1000) end,
        getCore = function() return core end,
        getTextManager = function() return realTM end,
        getText = function(k, ...) return k end,
        getTextOrNull = function(k) return k end,
        getTexture = function(p) return tex(p) end,
        isServer = function() return false end, isClient = function() return false end,
        getDebug = function() return false end,
        instanceof = function(o, cls)
            local n = type(o) == "table" and rawget(o, "__name") or ""
            if cls == "IsoPlayer" then return n == "IsoPlayer" end
            if cls == "Clothing" then return o.isClothing ~= nil and o:isClothing() end
            return false
        end,
        triggerEvent = noop,
        getPlayer = function() return world.player end,
        getSpecificPlayer = function() return world.player end,
        getPlayerScreenWidth = function() return 3840 end, getPlayerScreenHeight = function() return 2160 end,
        Perks = setmetatable({ None = nil }, { __index = function(_, k) return k end }),
        PerkFactory = {
            PerkList = nil,
            getPerk = function(t) return t end,
        },
        SkillBook = { Carpentry = { perk = "Carpentry" }, Cooking = { perk = "Cooking" }, Fishing = { perk = "Fishing" },
                      Trapping = { perk = "Trapping" }, Foraging = { perk = "Foraging" }, Tailoring = { perk = "Tailoring" } },
        ItemType = { LITERATURE = "LITERATURE" },
        getScriptManager = nil,
        CharacterTraitDefinition = { getCharacterTraitDefinition = function(id)
            return J("TraitDef", { getLabel = id, getDescription = "What " .. id .. " does, at some length to wrap.",
                getCost = (#id % 3 == 0) and -2 or 4,
                -- (the trait icons: one in two traits has a texture, as a mod's may have none)
                getTexture = (#id % 2 == 0) and J("Texture", { getWidth = 18, getHeight = 18 }) or false })
        end },
        CharacterProfessionDefinition = {
            getCharacterProfessionDefinition = function() return J("ProfDef", { getUIName = "carpenter" }) end,
            getProfessions = function() return JList({}) end,
        },
        getHairStylesInstance = function() return J("HairStyles", {
            FindFemaleStyle = function() return J("HairStyle", { getName = "Bob" }) end,
            FindMaleStyle = function() return J("HairStyle", { getName = "Short" }) end }) end,
        getBeardStylesInstance = function() return J("BeardStyles", {
            FindStyle = function() return J("BeardStyle", { getName = "Goatee" }) end }) end,
        SandboxVars = { StartMonth = 7, StartDay = 9, StartYear = 1 },
        BodyPartType = setmetatable({}, { __index = function(_, k) return partEnum[k] or k end }),
        Events = setmetatable({}, { __index = function(t, k) local e = { Add = noop, Remove = noop }; rawset(t, k, e); return e end }),
        ISUIElement = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end },
        ISScrollBar = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end },
        ISButton = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end },
        ISUI3DModel = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end },
        ISContextMenu = { get = function() return nil end },
        ISToolTip = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end },
        ISRichTextPanel = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end },
        ISUIHandler = { allUIVisible = true },
        UIManager = { getMillisSinceLastRender = function() return 16 end },
        Keyboard = setmetatable({}, { __index = function() return 0 end }),
        isKeyDown = function() return false end,
        getMouseX = function() return -1 end, getMouseY = function() return -1 end,
        getGameTime = function() return J("GameTime", { getWorldAgeHours = 100, getHour = 12, getMinutes = 0,
            getDay = 1, getMonth = 6, getYear = 1993, getTimeOfDay = 12, getMultiplier = 1 }) end,
        getSandboxOptions = function() return J("SandboxOptions", { getFirstYear = 1993 }) end,
        getActivatedMods = function() return JList({}) end,
        getSoundManager = function() return J("SoundManager", { playUISound = 0 }) end,
        getWorld = function() return J("World", { getGameMode = "Sandbox" }) end,
        getGameSpeed = function() return 1 end,
        getAllOutfits = function() return JList({}) end,
        Translator = { getLanguage = function() return J("Language", { name = "EN", toString = "EN" }) end },
        ZombRand = function(n) return 0 end,
        PZAPI = nil,
    }
    -- the UI base class: derive and new as ISPanel's
    local ISPanel = { Type = "ISPanel" }
    ISPanel.__index = ISPanel
    function ISPanel:derive(name) local o = { Type = name }; setmetatable(o, self); self.__index = self; o.__index = o; return o end
    function ISPanel:new(x, y, w, h) local o = { x = x, y = y, width = w, height = h }; setmetatable(o, self); self.__index = self; return o end
    for _, m in ipairs({ "initialise", "instantiate", "addChild", "removeChild", "setVisible", "addToUIManager",
                         "removeFromUIManager", "createChildren", "setCapture" }) do ISPanel[m] = noop end
    function ISPanel:getWidth() return self.width end
    function ISPanel:getHeight() return self.height end
    function ISPanel:setWidth(v) self.width = v end
    function ISPanel:setHeight(v) self.height = v end
    function ISPanel:setX(v) self.x = v end
    function ISPanel:setY(v) self.y = v end
    base.ISPanel = ISPanel
    base.ZeD_Panel = ISPanel:derive("ZeD_Panel")
    base.Texture = { getSharedTexture = function(p) return tex(p) end }
    -- (Kahlua's string.char takes past 255: Tr.lua's look-alikes, Scale's script probes)
    local str = {}
    for k, v in pairs(string) do str[k] = v end
    str.char = function(...) local t = { ... }; for i, c in ipairs(t) do if c > 255 then t[i] = 63 end end; return string.char(unpack(t)) end
    base.string = str
    base._G = env
    setmetatable(env, { __index = function(t, k)
        local v = base[k]
        if v ~= nil then return v end
        -- the rest of the game: written down; the UI classes (ZeD_*, IS*) a stub that answers anything, so the
        -- files load
        world.unknown = world.unknown or {}
        world.unknown[k] = (world.unknown[k] or 0) + 1
        if type(k) == "string" and (string.sub(k, 1, 4) == "ZeD_" or string.sub(k, 1, 2) == "IS") then
            local s
            s = setmetatable({}, { __index = function(_, kk) return s end, __call = function() return s end })
            rawset(t, k, s)
            return s
        end
        return nil
    end })
    world.player = buildPlayer()
    local PK = G.__PERKS
    base.PerkFactory.PerkList = JList(PK.list, "PerkList")
    base.Perks = setmetatable({}, { __index = function(_, k) if k == "None" then return PK.NONE end; return k end })
    base.getScriptManager = function()
        local books = {}
        for i, sk in ipairs({ "Carpentry", "Cooking", "Fishing", "Trapping", "Foraging", "Tailoring" }) do
            for v = 1, 5 do
                local title = sk .. " Vol. " .. v
                books[#books + 1] = J("ScriptItem", { isItemType = true, getSkillTrained = sk, getDisplayName = title,
                    getFullName = "Base.Book" .. sk .. v, getNumberOfPages = 220 })
            end
        end
        return J("ScriptManager", { getAllItems = JList(books) })
    end

    -- the files, in order, each in this world's env
    C = world.counts
    for _, path in ipairs(FILES) do
        local src = getSrc(path)
        check(label .. ": " .. path .. " found", src ~= nil)
        if src then
            local fn, err = loadstring(src, "@" .. path)
            check(label .. ": " .. path .. " compiles", fn ~= nil, err)
            if fn then
                setfenv(fn, env)
                local ok, e = pcall(fn)
                check(label .. ": " .. path .. " loads", ok, e)
            end
        end
    end
    local Z = env.ZeD
    world.ZeD = Z
    -- what the tabs read of the rest of ZeD
    -- a surface strip's claim on the window body goes in the frame's log with the draws; the help line's words
    -- in their own list (only their order among themselves counts: a stamp, read after the frame)
    local function note(s) if not world.nolog then world.frame[#world.frame + 1] = s end end
    local function noteHelp(s) if not world.nolog then world.helps[#world.helps + 1] = s end end
    -- (a recorder passes for its panel: ZeD.Help.set finds the window through its fields, which are the panel's)
    Z.Help = { set = function(p, text)
        if p.__name ~= "panel" then noteHelp("help from another panel") end
        noteHelp("help " .. tostring(text))
    end }
    Z.Surface = {
        fill = function(p, x, y, w, h, key)
            if not p or w <= 0 or h <= 0 then return end
            local c = Z.T[key or "surf2"] or Z.T.surf2
            p:drawRect(x, y, w, h, c.a or 1, c.r, c.g, c.b)
            note("claim " .. fmt(x) .. " " .. fmt(y) .. " " .. fmt(w) .. " " .. fmt(h))
        end,
        claim = function(p, x, y, w, h) note("claim " .. fmt(x) .. " " .. fmt(y) .. " " .. fmt(w) .. " " .. fmt(h)) end,
    }
    Z.KillTracker = Z.KillTracker or {}
    Z.KillTracker.total = function() return 41 end
    Z.Text._fontsSettled = true
    Z.Text.fallback = false
    Z.Text.checkRoleFonts = function() return false end
    Z.Scale._root = 1.75
    Z.Scale.root = function() return 1.75 end
    Z.applyTheme("dark", "orange", "small")
    -- a fresh look at the measure store each frame: the same as OnPreUIDraw
    world.wrapCounts = Z.Atoms._wrapMemo
    -- count the wraps and truncates asked for
    local A = Z.Atoms
    local w0, t0 = A.wrapText, A.truncateText
    A.wrapText = function(...) C.wrap = C.wrap + 1; return w0(...) end
    A.truncateText = function(...) C.trunc = C.trunc + 1; return t0(...) end
    -- each framed fill bar's inside, written down with the frame's draws (log runs only): its cells may move
    -- (equal cells now), so the comparison looks at them cell by cell instead of pixel by pixel
    local sb0 = A.drawSegBar
    A.drawSegBar = function(panel, x, y, w, h, n, k, on, off, gap, opts)
        if opts and opts.framed and not world.nolog and world.cmds then
            local T = Z.T
            local fh = opts.exactH and h or math.max(h, T.px(8))
            local bw = T.line(T.borderW)
            local b = T.base
            world.cmds[#world.cmds + 1] = { "bar", 0, x + bw, y + bw, w - 2 * bw, fh - 2 * bw, b.r, b.g, b.b }
        end
        return sb0(panel, x, y, w, h, n, k, on, off, gap, opts)
    end
    return world
end

-- ===========================================================================
-- THE WINDOW AND THE FRAMES
-- ===========================================================================
local function newWin(world)
    return {
        _playerObj = world.player, playerNum = 0,
        _skillsScroll = newScroll(), _thermalScroll = newScroll(), _identityScroll = newScroll(), _equipScroll = newScroll(),
        _skillsGridExpanded = true, _thermalFigureExpanded = true, _identityPhotoExpanded = false,
        _equipListExpanded = true, _pinnedSkills = { "Carpentry" }, _trainingExpanded = { col1_Cooking = true },
        getAbsoluteX = function() return 0 end, getAbsoluteY = function() return 0 end,
        getWidth = function() return 1800 end, getHeight = function() return 1600 end,
        addChild = noop,
    }
end

-- (the variants the counts are not reported for: the same frames compared, at the half card, with the
-- other style, the photo or the figure folded the other way)
local HALF = 385   -- (the half card at 1.75x: 220 units)
local TABS = {
    { id = "skills", name = "Skills", fn = function(Z) return Z.SkillsTab.render end },
    { id = "thermal", name = "Thermal", fn = function(Z) return Z.ThermalTab.render end },
    { id = "identity", name = "Identity", fn = function(Z) return Z.IdentityTab.render end },
    { id = "equip", name = "Equip list", fn = function(Z) return Z.EquipmentTab.render end, view = 1 },
    { id = "equip", name = "Equip doll", fn = function(Z) return Z.EquipmentTab.render end, view = 2 },
    { id = "skills", name = "Skills, half card", fn = function(Z) return Z.SkillsTab.render end, W = HALF, variant = true },
    { id = "thermal", name = "Thermal, figure folded", fn = function(Z) return Z.ThermalTab.render end, variant = true,
      setup = function(Z, win) win._thermalFigureExpanded = false; win._thermalView = 1 end },
    { id = "thermal", name = "Thermal, insulation view", fn = function(Z) return Z.ThermalTab.render end, variant = true,
      setup = function(Z, win) win._thermalView = 5 end },
    { id = "identity", name = "Identity, half card", fn = function(Z) return Z.IdentityTab.render end, W = HALF, variant = true },
    { id = "identity", name = "Identity, full photo", fn = function(Z) return Z.IdentityTab.render end, variant = true,
      setup = function(Z, win) win._identityPhotoExpanded = true end },
    { id = "identity", name = "Identity, Simple", fn = function(Z) return Z.IdentityTab.render end, variant = true,
      setup = function(Z, win) Z.IdentityTab.qaStyle = "simple" end, teardown = function(Z) Z.IdentityTab.qaStyle = nil end },
    { id = "identity", name = "Identity, Simple, half card", fn = function(Z) return Z.IdentityTab.render end, W = HALF,
      variant = true, setup = function(Z, win) Z.IdentityTab.qaStyle = "simple" end,
      teardown = function(Z) Z.IdentityTab.qaStyle = nil end },
    { id = "equip", name = "Equip list, half card", fn = function(Z) return Z.EquipmentTab.render end, view = 1, W = HALF,
      variant = true },
}
-- A window's own colours, as ZeD_Window swaps them into ZeD.T for its drawing: from frame 30 its accent and
-- text colours (other tables), from frame 45 its see-through surfaces in tables of its own whose alpha moves
-- each frame (fading to solid in use), from frame 65 the theme's own again. The kept draws must follow.
local SWAP_KEYS = { "accent", "hover", "text", "textHead", "textDim", "toneHi", "toneLo", "border", "borderS" }
local SURF = { "base", "surf1", "surf2", "surf3", "surf4" }
local function windowColours(Z, f, st)
    local T = Z.T
    if f == 30 then
        st.saved = {}
        for _, k in ipairs(SWAP_KEYS) do
            local c = T[k]
            st.saved[k] = c
            T[k] = { r = c.b, g = c.r, b = c.g, a = c.a }
        end
    end
    if f >= 45 and f < 65 then
        st.mine = st.mine or {}
        st.surf = st.surf or {}
        for _, k in ipairs(SURF) do
            if not st.surf[k] then st.surf[k] = T[k] end
            local c = st.surf[k]
            local m = st.mine[k] or {}
            st.mine[k] = m
            m.r, m.g, m.b, m.a = c.r, c.g, c.b, 0.6 + ((f - 45) % 7) * 0.05
            T[k] = m
        end
    end
    if f == 65 then
        for k, c in pairs(st.saved or {}) do T[k] = c end
        for k, c in pairs(st.surf or {}) do T[k] = c end
    end
end
for _, base in ipairs({ { "skills", "Skills" }, { "thermal", "Thermal" }, { "identity", "Identity" }, { "equip", "Equip list" } }) do
    local src
    for _, t in ipairs(TABS) do if t.name == base[2] then src = t end end
    TABS[#TABS + 1] = { id = src.id, name = base[2] .. ", the window's own colours", fn = src.fn, view = src.view,
                        variant = true, frame = windowColours }
end

-- Calls n deep (not tail calls) with room for locals at each: this Lua's full collect shrinks the stack and
-- its call list, and a frame that grew them back counted it as memory the tab allocates (a deeper call
-- chain, more "memory"). They are grown back before the frame is measured. (Kahlua has no such count.)
local function stackRoom(n)
    if n <= 0 then return 0 end
    local a, b, c, d, e, f, g, h = n, n, n, n, n, n, n, n
    local r = stackRoom(n - 1)
    return r + a - b + c - d + e - f + g - h
end

-- one tab, N frames. mode "log": every draw of every frame written down; "count": the instructions (a count
-- hook) and the calls; "mem": the memory a frame allocates (nothing else running: no log, no hook)
local function runTab(world, tab, frames, pointer, mode, profile)
    world.nolog = mode ~= "log"
    local Z = world.ZeD
    Z.Settings = { equipViewOption = { getValue = function() return tab.view or 1 end } }
    clock.ms = 1700000000000
    Z._throttleN = 0
    local win = newWin(world)
    local panel = newPanel(world)
    Z.LeanDraw = { drawRect = panel.drawRect }   -- (its rects are the plain ones: ZeD.Atoms.lineJo draws from the line textures)
    local render = tab.fn(Z)
    local W, H = tab.W or 840, 1500   -- (the full card at 4K 1.75x: 480 units)
    if tab.setup then tab.setup(Z, win) end
    local frameState = {}
    local out = { frames = {}, cmds = {}, helps = {}, instr = 0, alloc = 0 }
    world.counts = newCounts()
    C = world.counts
    local prof = profile and {} or nil
    if profile then C.byCaller = {} end
    local hookN = 0
    local STEP = 7   -- (a small prime: the samples in the stand-ins, left out, cost the count little)
    -- (a sample in the stand-ins themselves is not the tab's work: left out)
    -- (-prof: the memory grown since the last sample goes to the function running now, the hook's own left out)
    local profA = profile and {} or nil
    local lastM = nil
    local function hook()
        local m = profA and collectgarbage("count")
        local info = debug.getinfo(2, LINEPROF and "Sl" or "S")
        local src = info and info.short_src or ""
        local stub = string.find(src, "drawer_tabs_perf_sim", 1, true)
        if not stub then hookN = hookN + 1 end
        if prof then
            local k = stub and "(the stand-ins)" or (src .. ":" .. tostring(LINEPROF and info.currentline or info.linedefined))
            if not stub then prof[k] = (prof[k] or 0) + 1 end
            if lastM then profA[k] = (profA[k] or 0) + (m - lastM) end
            lastM = collectgarbage("count")
        end
    end
    for f = 1, frames do
        clock.ms = clock.ms + 16
        if tab.frame then tab.frame(Z, f, frameState) end
        if pointer then
            -- (down the card in small steps, in turn over the left and right columns' bars, the names, the figure)
            local XS = { 365, 395, 785, 805, 520, 150, 300, 700 }
            panel.mx, panel.my = XS[(f % #XS) + 1], 40 + (f * 11) % 1460
        else
            panel.mx, panel.my = -500, -500
        end
        world.frame, world.helps, world.cmds = {}, {}, {}
        if f == 21 then hookN = 0 end   -- (the first frames fill the caches: the work counted from the 21st)
        collectgarbage("collect")
        collectgarbage("stop")
        stackRoom(400)   -- (the full collect above shrinks the Lua stack: grown back here, not counted as the tab's)
        local m0 = collectgarbage("count")
        lastM = nil
        if mode == "count" then debug.sethook(hook, "", STEP) end
        local ok, err = pcall(render, panel, win, 0, 0, W, H)
        if mode == "count" then debug.sethook() end
        local m1 = collectgarbage("count")
        collectgarbage("restart")
        if not ok then
            check(world.label .. " " .. tab.name .. " frame " .. f .. " draws", false, err)
            break
        end
        if f > 20 then out.alloc = out.alloc + (m1 - m0) end
        out.frames[f] = table.concat(world.frame, "\n")
        out.helps[f] = table.concat(world.helps, "\n")
        if mode == "log" then out.cmds[f] = world.cmds end
    end
    if tab.teardown then tab.teardown(Z) end
    out.instr = hookN * STEP * frames / (frames - 20)
    out.counts = world.counts
    out.prof, out.profA = prof, profA
    out.n = frames
    return out
end

-- ===========================================================================
-- RUN
-- ===========================================================================
local newW = newWorld("new", readFile)
local oldW = nil
local hasBase = BASE ~= nil and gitShow(FILES[1]) ~= nil
if hasBase then oldW = newWorld("old", gitShow)
elseif BASE then check("the base " .. BASE .. " has the files", false)
else print("(no base given: the checkout alone, every frame drawn and counted, nothing compared; to compare, give a revision such as origin/main)") end

-- ===========================================================================
-- PAINTING A FRAME: where the draws differ (a line texture for rects), the pixels must not
-- ===========================================================================
local LINETEX = dofile(ROOT .. "ZeDUI/tools/qa/linetex_pixels.lua")
local function lineTexOf(t)
    local n = type(t) == "table" and rawget(t, "__name")
    local m = n and string.match(n, "lines/([%w_]+)%.png$")
    return m and LINETEX[m] or nil
end
-- seg.png by its rule (make_line_tex.py checks the PNG against it): row (gap - 1) * 64 + (cell - 1), gap lit, cell clear
LINETEX.seg = { w = 1024, h = 256, rule = function(u, v)
    if u < 0 or u >= 1024 or v < 0 or v >= 256 then return false end
    local g, c = math.floor(v / 64) + 1, v - math.floor(v / 64) * 64 + 1
    return u - math.floor(u / (c + g)) * (c + g) < g
end }
local function texelLit(tx, u, v)
    if tx.rule then return tx.rule(u, v) end
    local row = tx.rows[v + 1]
    if not row or u < 0 then return false end
    for i = 1, #row, 2 do if u >= row[i] and u < row[i + 1] then return true end end
    return false
end
-- a draw that only stands for itself (a word, a picture): a block in a colour from its name, the same both ways
local function token(s)
    local h = 7
    for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 9973 end
    return (h % 97) / 97, (h % 89) / 89, (h % 83) / 83
end
local function newCanvas() return { R = {}, G = {}, B = {} } end
local function blendPx(cv, px, py, r, g, b, a)
    if px < -64 or px > 1100 or py < -64 or py > 1800 then return end
    local i = py * 8192 + px
    cv.R[i] = r * a + (cv.R[i] or 0) * (1 - a)
    cv.G[i] = g * a + (cv.G[i] or 0) * (1 - a)
    cv.B[i] = b * a + (cv.B[i] or 0) * (1 - a)
end
-- the pixels whose centres are inside the rect
local function fillRect(cv, x, y, w, h, r, g, b, a)
    local x0, x1 = math.ceil(x - 0.5), math.ceil(x + w - 0.5) - 1
    local y0, y1 = math.ceil(y - 0.5), math.ceil(y + h - 0.5) - 1
    for py = math.max(y0, -64), math.min(y1, 1800) do
        for px = math.max(x0, -64), math.min(x1, 1100) do blendPx(cv, px, py, r, g, b, a) end
    end
end
local TEXT = { drawText = 0, drawTextRight = 1, drawTextCentre = 0.5, drawTextZoomed = 0 }
local function paint(cmds)
    local cv = newCanvas()
    for _, c in ipairs(cmds or {}) do
        local k = c[1]
        if k == "drawRect" then
            fillRect(cv, c[3], c[4], c[5], c[6], c[8], c[9], c[10], c[7])
        elseif k == "drawRectBorder" then
            local x, y, w, h, a, r, g, b = c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10]
            fillRect(cv, x, y, 1, h, r, g, b, a); fillRect(cv, x + 1, y, w - 2, 1, r, g, b, a)
            fillRect(cv, x + w - 1, y, 1, h, r, g, b, a); fillRect(cv, x + 1, y + h - 1, w - 2, 1, r, g, b, a)
        elseif TEXT[k] then
            local s = tostring(c[3])
            local r, g, b = token(k .. s)
            fillRect(cv, c[4] - TEXT[k] * 4 * #s, c[5], 4 * #s, 8, r, g, b, 1)
        elseif k == "jo:DrawSubTextureRGBA" and lineTexOf(c[3]) then
            local tx = lineTexOf(c[3])
            local sx, sy, sw, sh, dx, dy, dw, dh = c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11]
            local r, g, b, a = c[12], c[13], c[14], c[15]
            for py = math.ceil(dy - 0.5), math.ceil(dy + dh - 0.5) - 1 do
                for px = math.ceil(dx - 0.5), math.ceil(dx + dw - 0.5) - 1 do
                    local u = sx + math.floor((px + 0.5 - dx) * sw / dw)
                    local v = sy + math.floor((py + 0.5 - dy) * sh / dh)
                    if texelLit(tx, u, v) then blendPx(cv, px, py, r, g, b, a) end
                end
            end
        elseif string.sub(k, 1, 4) == "draw" or string.sub(k, 1, 3) == "jo:" then
            -- a picture: a block where it lands, in a colour from what it is
            local name = tostring(type(c[3]) == "table" and rawget(c[3], "__name") or c[3])
            local r, g, b = token(k .. name)
            local x, y, w, h = c[4], c[5], 32, 32
            if k == "drawTextureScaled" or k == "drawTextureScaledAspect" then w, h = c[6], c[7]
            elseif k == "drawTextureScaledUniform" then w, h = 32 * c[6], 32 * c[6]
            elseif k == "jo:DrawSubTextureRGBA" then x, y, w, h = c[8], c[9], c[10], c[11] end
            if type(x) == "number" and type(y) == "number" then fillRect(cv, x, y, w or 32, h or 32, r, g, b, 1) end
        end
    end
    return cv
end
-- the framed fill bars' insides a frame drew ({ x, y, w, h, base r, g, b })
local function barsOf(cmds)
    local out = {}
    for _, c in ipairs(cmds or {}) do
        if c[1] == "bar" then out[#out + 1] = { c[3], c[4], c[5], c[6], c[7], c[8], c[9] } end
    end
    return out
end
local function inBar(bars, px, py)
    for _, b in ipairs(bars) do
        if px + 0.5 >= b[1] and px + 0.5 < b[1] + b[3] and py + 0.5 >= b[2] and py + 0.5 < b[2] + b[4] then return true end
    end
    return false
end
-- a bar's cells along its middle row: the runs of pixels that are not the well's colour, { start, width, r, g, b }
local function barCells(cv, b)
    local py = math.floor(b[2] + b[4] / 2)
    local runs, cur = {}, nil
    for px = math.ceil(b[1] - 0.5), math.ceil(b[1] + b[3] - 0.5) - 1 do
        local i = py * 8192 + px
        local r, g, bl = cv.R[i] or 0, cv.G[i] or 0, cv.B[i] or 0
        local well = math.abs(r - b[5]) < 1e-9 and math.abs(g - b[6]) < 1e-9 and math.abs(bl - b[7]) < 1e-9
        if well then cur = nil
        elseif cur and math.abs(cur[3] - r) < 1e-9 and math.abs(cur[4] - g) < 1e-9 and math.abs(cur[5] - bl) < 1e-9 then
            cur[2] = cur[2] + 1
        else
            cur = { px, 1, r, g, bl }
            runs[#runs + 1] = cur
        end
    end
    return runs
end
-- Outside the bars, every pixel the same; inside, the same cells in the same colours: every cell within a pixel
-- of the others (the spare pixels spread one a cell from the ends, Nov 10 2026), the middle ones within a pixel of
-- the old cell's; a bar whose cells met the frame at both ends still meets it.
local function sameCanvas(a, b, bars)
    for _, ch in ipairs({ "R", "G", "B" }) do
        local A, B = a[ch], b[ch]
        for i, v in pairs(A) do
            local px, py = i % 8192, math.floor(i / 8192)
            if math.abs(v - (B[i] or 0)) > 1e-9 and not inBar(bars, px, py) then return px .. "," .. py end
        end
        for i, v in pairs(B) do
            local px, py = i % 8192, math.floor(i / 8192)
            if math.abs(v - (A[i] or 0)) > 1e-9 and not inBar(bars, px, py) then return px .. "," .. py end
        end
    end
    for _, bar in ipairs(bars) do
        local o, n = barCells(a, bar), barCells(b, bar)
        local where = "the bar at " .. fmt(bar[1]) .. "," .. fmt(bar[2])
        if #o ~= #n then return where .. ": " .. #o .. " cells before, " .. #n .. " now" end
        local x0, x1 = math.ceil(bar[1] - 0.5), math.ceil(bar[1] + bar[3] - 0.5)
        for i = 1, #n do
            if math.abs(o[i][3] - n[i][3]) > 1e-9 or math.abs(o[i][4] - n[i][4]) > 1e-9 or math.abs(o[i][5] - n[i][5]) > 1e-9 then
                return where .. ": cell " .. i .. " another colour"
            end
        end
        -- the ends: a bar that met the frame on a side still meets it
        if #o > 0 then
            if o[1][1] == x0 and n[1][1] ~= x0 then return where .. ": the first cell no longer meets the frame" end
            if o[#o][1] + o[#o][2] == x1 and n[#n][1] + n[#n][2] ~= x1 then return where .. ": the last cell no longer meets the frame" end
        end
        if #n > 2 then
            -- every cell within a pixel of the others (the director, Nov 10 2026: "Keep 10, spread evenly"), the cells
            -- drawn running to the bar's far end when they did; each within a pixel of the old cell's
            local mn, mx = 1e9, 0
            for i = 1, #n do mn = math.min(mn, n[i][2]); mx = math.max(mx, n[i][2]) end
            if mx - mn > 1 then return where .. ": cells " .. mn .. " to " .. mx .. " px wide (more than a pixel apart)" end
            for i = 2, #n - 1 do
                if math.abs(o[i][2] - n[i][2]) > 1 then
                    return where .. ": cell " .. i .. " " .. o[i][2] .. " px before, " .. n[i][2] .. " now"
                end
            end
        end
    end
    return nil
end
-- every draw but the thin ones (a 1 to 3 px rect: a chevron's row, a dash; a draw from a line texture) and the bars'
-- insides (the well, the cells and their gaps: compared painted, cell by cell), word for word
local function thickSeq(cmds)
    local out = {}
    local bars = barsOf(cmds)
    for _, c in ipairs(cmds or {}) do
        local k = c[1]
        local thin = (k == "drawRect" and (c[5] <= 3 or c[6] <= 3)) or (k == "jo:DrawSubTextureRGBA" and lineTexOf(c[3]) ~= nil)
        if not thin and k == "drawRect" then
            for _, b in ipairs(bars) do
                local x, y, w, h = c[3], c[4], c[5], c[6]
                if x >= b[1] and y >= b[2] and x + w <= b[1] + b[3] and y + h <= b[2] + b[4]
                   then thin = true; break end
            end
        end
        if not thin then
            local parts = { k }
            for i = 3, c[2] + 2 do parts[#parts + 1] = fmt(c[i]) end
            out[#out + 1] = table.concat(parts, " ")
        end
    end
    return table.concat(out, "\n")
end
local paintedRows = {}
-- (ONLY=<words> in the environment: just the tabs whose name holds them)
do
    local only = os.getenv("ONLY")
    if only then
        local keep = {}
        for _, t in ipairs(TABS) do if string.find(t.name, only, 1, true) then keep[#keep + 1] = t end end
        TABS = keep
    end
end

local FRAMES = 80
section("frames: " .. FRAMES .. " per tab, 16 ms apart, at 1.75x (the full card, 840 x 1500 px)")
local rows = {}
for _, tab in ipairs(TABS) do
    for _, pointer in ipairs({ false, true }) do
        local label = tab.name .. (pointer and " (pointer over)" or "")
        local nl = runTab(newW, tab, FRAMES, pointer, "log")
        local ol = oldW and runTab(oldW, tab, FRAMES, pointer, "log")
        local n, o = nil, nil
        if not tab.variant then
            n = runTab(newW, tab, FRAMES, pointer, "count", PROF and not pointer)
            o = oldW and runTab(oldW, tab, FRAMES, pointer, "count")
            n.alloc = runTab(newW, tab, FRAMES, pointer, "mem").alloc
            if o then o.alloc = runTab(oldW, tab, FRAMES, pointer, "mem").alloc end
        end
        if not ol then check(label .. ": " .. FRAMES .. " frames drawn", #nl.frames == FRAMES) end
        if ol then
            -- each frame: the help lines the same; the draws the same word for word, or else every draw but the
            -- thin ones the same and (sampled) the painted pixels the same
            local same, first, painted = 0, nil, 0
            for f = 1, FRAMES do
                local ok = ol.helps[f] == nl.helps[f]
                if ok and ol.frames[f] ~= nl.frames[f] then
                    ok = thickSeq(ol.cmds[f]) == thickSeq(nl.cmds[f])
                    if ok and (f == 21 or f == 50 or f == FRAMES) then
                        painted = painted + 1
                        local a, b = paint(ol.cmds[f]), paint(nl.cmds[f])
                        local diff = sameCanvas(a, b, barsOf(nl.cmds[f]))
                        if diff then ok = false; print("  " .. label .. " frame " .. f .. ": a pixel differs at " .. diff) end
                    end
                end
                if ok then same = same + 1 elseif not first then first = f end
            end
            check(label .. ": " .. FRAMES .. " frames drawn", #nl.frames == FRAMES and #ol.frames == FRAMES)
            if pointer and not tab.variant then
                -- (the pointer's path crosses rows and bars: some frames carry a help line, so those are compared too)
                local withHelp = 0
                for f = 1, FRAMES do if (nl.helps[f] or "") ~= "" then withHelp = withHelp + 1 end end
                check(label .. ": the pointer brings up help lines", withHelp > 0, withHelp)
            end
            check(label .. ": every frame draws the same as before", same == FRAMES, same .. "/" .. FRAMES)
            if painted > 0 then paintedRows[#paintedRows + 1] = "  " .. label .. ": " .. painted .. " frames painted both ways" end
            if first and failed <= 3 then
                local a, b = ol.frames[first] or "", nl.frames[first] or ""
                local la, lb = {}, {}
                for l in string.gmatch(a, "[^\n]+") do la[#la + 1] = l end
                for l in string.gmatch(b, "[^\n]+") do lb[#lb + 1] = l end
                for i = 1, math.max(#la, #lb) do
                    if la[i] ~= lb[i] then print("  frame " .. first .. " draw " .. i .. ":\n    old " .. tostring(la[i]) .. "\n    new " .. tostring(lb[i])); break end
                end
            end
        end
        if n then
        local function per(r, k) return r.counts[k] / FRAMES end
        local function line(tag, r)
            return string.format("    %s instr %7.0f  java %6.1f  draws %5.1f  measures %6.2f  wraps %5.1f  truncs %5.1f  alloc %6.1f KB",
                tag, r.instr / FRAMES, per(r, "java"), per(r, "draw"), per(r, "measure"), per(r, "wrap"), per(r, "trunc"),
                r.alloc / (FRAMES - 20))
        end
        rows[#rows + 1] = "  " .. label
        if o then rows[#rows + 1] = line("old", o) end
        rows[#rows + 1] = line("new", n)
        if o and not PROF then   -- (-prof: the profile's own work is in the new count)
            check(label .. ": no more Lua work than before", n.instr <= o.instr * 1.02, n.instr .. " vs " .. o.instr)
            check(label .. ": no more draws than before", n.counts.draw <= o.counts.draw, n.counts.draw .. " vs " .. o.counts.draw)
            check(label .. ": no more Java calls than before", n.counts.java <= o.counts.java, n.counts.java .. " vs " .. o.counts.java)
            -- (the memory a frame allocates, GC stopped: exact in this Lua, so the base's figure is the limit)
            check(label .. ": no more memory a frame than before", n.alloc <= o.alloc + 0.01,
                string.format("%.2f vs %.2f KB", n.alloc / (FRAMES - 20), o.alloc / (FRAMES - 20)))
        end
        if n.prof then
            local list = {}
            for k, v in pairs(n.prof) do list[#list + 1] = { k, v } end
            table.sort(list, function(a, b) return a[2] > b[2] end)
            rows[#rows + 1] = "    where the instructions go (new):"
            for i = 1, math.min(PROF_N or 14, #list) do
                rows[#rows + 1] = string.format("      %5.1f%%  %s", 100 * list[i][2] / math.max(1, n.instr / 100), list[i][1])
            end
            local jl = {}
            for k, v in pairs(n.counts.byJava) do jl[#jl + 1] = { k, v } end
            table.sort(jl, function(a, b) return a[2] > b[2] end)
            local s = {}
            for i = 1, math.min(10, #jl) do s[#s + 1] = jl[i][1] .. " " .. string.format("%.1f", jl[i][2] / FRAMES) end
            rows[#rows + 1] = "    java calls a frame: " .. table.concat(s, ", ")
            local dl = {}
            for k, v in pairs(n.counts.byCaller or {}) do dl[#dl + 1] = { k, v } end
            table.sort(dl, function(a, b) return a[2] > b[2] end)
            s = {}
            for i = 1, math.min(10, #dl) do s[#s + 1] = dl[i][1] .. " " .. string.format("%.1f", dl[i][2] / FRAMES) end
            rows[#rows + 1] = "    draws a frame by who asks: " .. table.concat(s, ", ")
            local al = {}
            for k, v in pairs(n.profA or {}) do al[#al + 1] = { k, v } end
            table.sort(al, function(a, b) return a[2] > b[2] end)
            s = {}
            for i = 1, math.min(12, #al) do s[#s + 1] = al[i][1] .. " " .. string.format("%.2f", al[i][2] / (FRAMES - 20)) end
            rows[#rows + 1] = "    memory a frame (KB, about) by who allocates: " .. table.concat(s, ", ")
        end
        end
    end
end
for _, r in ipairs(rows) do print(r) end
for _, r in ipairs(paintedRows) do print(r) end
if newW.unknown then
    local u = {}
    for k in pairs(newW.unknown) do u[#u + 1] = k end
    table.sort(u)
    print("  (globals the stubs answer blind: " .. table.concat(u, ", ") .. ")")
end

print("drawer_tabs_perf_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
