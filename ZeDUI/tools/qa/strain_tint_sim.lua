-- ZeDUI/tools/qa/strain_tint_sim.lua  (Strain, the director, Nov 22 2026): muscle strain on the body figure and in the
-- Health summary, with no game running. The director's calls (QA's questions A1 and B1):
--   A1  strained parts show on the body figure in a tint of their own (the theme's strainMinor / strainHeavy), minor at
--       5 or more and heavy at 20 or more (the game's health panel: Minor Muscle Strain / Muscle Strain); a wound's
--       colour wins on the same part; on the Health tab's figure and the medical card's only ("No, Health only.":
--       Thermal and Equipment's defense view keep their temperature and defense colours)
--   B1  the summary counts strain apart from injuries: strain alone reads "No injuries, Muscle Strain: 6" (the game's
--       own word, IGUI_health_Stiffness); wounds and strain give the injured count, then "Muscle Strain: 6 of 17"
-- The REAL HealthTab.lua runs on Lua 5.1 stubs of the body (17 parts). It checks:
--   LEVEL    4.9 is none, 5 and 19.9 minor, 20 and 100 heavy
--   FIGURE   the Health tab's own figure draw: a strained healthy part in the minor / heavy tint; a part at 80 or less, a
--            wound (a scratch), another mod's line: the health colour wins; bandage, pain or stitches alone: the strain
--            tint (care is no wound); an unstrained part keeps its health colour
--   COUNTS   strainedCount is every part at 5 or more; woundedCount leaves out a part with strain alone; strainWorst
--   SUMMARY  the four cases' words and dots; the line count the measure reads is the lines drawn
--   WIRING   ObjectCardMedic draws with figureColor and drawSummary (trade_medic_sim runs it); ThermalTab, ProtectionTab
--            and EquipmentTab read no strain and draw no strain tint (Health only); HealthTab has no strainMap left
--   WORDS    the two new keys in EN and NL UI.json and the translators' context file, with their placeholders
-- What it can't show: the tints on screen (QA's rt_strain in game).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/strain_tint_sim.lua
-- It prints FAIL lines and a last line "strain_tint_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]strain_tint_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local TR = ROOT .. "42/media/lua/shared/Translate/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end

-- ---------------------------------------------------------------------------
-- The game, as stubs
-- ---------------------------------------------------------------------------
require = function() end
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function() end, Remove = function() end }
    rawset(t, k, e)
    return e
end })
-- the words: the game's "Muscle Strain" and ZeD's English, from the files
local WORDS = { IGUI_health_Stiffness = "Muscle Strain", IGUI_health_MinorStiffness = "Minor Muscle Strain" }
do
    local s = readFile(TR .. "EN/UI.json") or ""
    for k, v in s:gmatch('"(UI_ZeD_Health_[%w_]+)"%s*:%s*"([^"]*)"') do WORDS[k] = v end
end
local function fill(s, ...)
    local args = { ... }
    return (s:gsub("%%(%d)", function(n) local v = args[tonumber(n)]; return v ~= nil and tostring(v) or ("%" .. n) end))
end
getText = function(k, ...) return fill(WORDS[k] or ("T:" .. tostring(k)), ...) end
getTextOrNull = function() return nil end
Perks = { Doctor = "Doctor" }
ISHealthPanel = { cheat = false }
local PARTS = { "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin", "UpperArm_L", "UpperArm_R", "ForeArm_L",
    "ForeArm_R", "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }
BodyPartType = { getDisplayName = function(t) return "Part " .. tostring(t) end, ToString = function(t) return tostring(t) end }
for _, n in ipairs(PARTS) do BodyPartType[n] = n end
local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end

local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end
local FIGS = {}
ZeD_BodyFigure = {}
function ZeD_BodyFigure:new() local o = { colors = {} }; setmetatable(o, { __index = ZeD_BodyFigure }); FIGS[#FIGS + 1] = o; return o end
function ZeD_BodyFigure:initialise() end
function ZeD_BodyFigure:loadTextures() end
function ZeD_BodyFigure:setSex() end
function ZeD_BodyFigure:setPartColor(n, r, g, b, a) self.colors[n] = { r = r, g = g, b = b, a = a } end
function ZeD_BodyFigure:clearPartColor(n) self.colors[n] = nil end
function ZeD_BodyFigure:drawAt() end
-- the wounds and skin tone gatherData hands the figure, and the tab's wounds and chart (Design, Nov 22 2026)
function ZeD_BodyFigure.woundsFrom() return nil end
function ZeD_BodyFigure.skinToneOf() return 0 end
function ZeD_BodyFigure:setSkinTone() end
function ZeD_BodyFigure:setPartWounds() end
function ZeD_BodyFigure:drawChart() end
local DRAWN = {}
ZeD = {
    T = { px = function(n) return n end, sp = { sm = 10, xs = 6 }, fontF1 = "F1", fontF2 = "F2",
          positive = col(0, 1, 0), warning = col(1, 1, 0), danger = col(1, 0, 0), accent = col(0, 0, 1), info = col(0, 1, 1),
          strainMinor = col(0.8, 0.7, 0.95), strainHeavy = col(0.55, 0.25, 0.8) },
    TM = { getFontHeight = function() return 14 end },
    logOnce = function() end,
    textCase = function(s) return s end,
    Atoms = {
        safeGet = function(o, m, ...) local f = o and o[m]; if not f then return nil end; local ok, r = pcall(f, o, ...); if ok then return r end end,
        drawStatusDot = function(p, x, y, c) DRAWN[#DRAWN + 1] = { dot = c, y = y } end,
        drawBody = function(p, s, x, y) DRAWN[#DRAWN + 1] = { text = s, y = y } end,
    },
}
ZeD.tr = function(k, ...) return getText(k, ...) end

local src = readFile(Z .. "HealthTab.lua")
check("HealthTab.lua is read", src ~= nil)
local fn, err = loadstring(src or "", "=HealthTab.lua")
check("HealthTab.lua loads", fn ~= nil, err)
if fn then fn() end
local H = ZeD.HealthTab or {}

-- a body: parts by name with a state table each (nil getters read 0 or false)
local function newBody(states)
    local parts = {}
    for i, n in ipairs(PARTS) do
        local s = states[n] or {}
        parts[i] = setmetatable({}, { __index = function(_, k)
            if k == "getType" then return function() return n end end
            if k == "getHealth" then return function() return s.health or 100 end end
            return function() local v = s[k]; if v == nil then return 0 end; return v end
        end })
        -- (booleans the rules read as flags: false, not 0, when not set)
        for _, flag in ipairs({ "bitten", "bleeding", "deepWounded", "isInfectedWound", "haveBullet", "haveGlass",
                                "scratched", "isCut", "isNeedBurnWash", "bandaged", "stitched" }) do
            if s[flag] == nil then s[flag] = false end
        end
    end
    local list = jlist(parts)
    return { getBodyParts = function() return list end, getOverallBodyHealth = function() return 90 end }
end
local function newPlayer(body)
    return { getBodyDamage = function() return body end, getPerkLevel = function() return 0 end,
             isFemale = function() return false end }
end
local function same(a, b) return a and b and a.r == b.r and a.g == b.g and a.b == b.b end

-- ---------------------------------------------------------------------------
section("LEVEL")
check("the helpers are on ZeD.HealthTab", H.strainLevel and H.strainColor and H.figureColor and H.summaryLines
      and H.summaryLineCount and H.drawSummary)
if H.strainLevel then
    check("4.9: no strain", H.strainLevel(4.9) == nil)
    check("5: minor", H.strainLevel(5) == 1)
    check("19.9: minor", H.strainLevel(19.9) == 1)
    check("20: heavy", H.strainLevel(20) == 2)
    check("100: heavy", H.strainLevel(100) == 2)
    check("the tints are the theme's", same(H.strainColor(1), ZeD.T.strainMinor) and same(H.strainColor(2), ZeD.T.strainHeavy))
end

-- ---------------------------------------------------------------------------
section("FIGURE (the Health tab's own draw)")
local states = {
    ForeArm_R  = { getStiffness = 10 },                               -- minor, healthy: minor tint
    UpperArm_R = { getStiffness = 40 },                               -- heavy, healthy: heavy tint
    ForeArm_L  = { getStiffness = 4 },                                -- under 5: health colour
    UpperArm_L = { getStiffness = 40, health = 80 },                  -- 80: the health colour (warning) wins
    Hand_L     = { getStiffness = 40, scratched = true, getScratchTime = 5 },  -- a wound: its colour wins
    Hand_R     = { getStiffness = 12, bandaged = true, getBandageLife = 1, getAdditionalPain = 30, stitched = true },  -- care only
    UpperLeg_L = { getStiffness = 25, health = 95 },                  -- heavy, health over 80: heavy tint
}
local data = H.gatherData and H.gatherData(newPlayer(newBody(states))) or {}
local win = { _playerObj = nil }
local okDraw, errDraw = pcall(H._drawBodyFigure, nil, win, data, 0, 0, 106, 254)
check("the figure draws without an error", okDraw, errDraw)
local fig = win._healthBodyFigure
local function tint(n) return fig and fig.colors[n] end
check("a minor strain (10) in the minor tint", same(tint("Right Forearm"), ZeD.T.strainMinor))
check("a heavy strain (40) in the heavy tint", same(tint("Right Upper Arm"), ZeD.T.strainHeavy))
check("under 5: no tint (a healthy part, the director Nov 23)", tint("Left Forearm") == nil)
check("health 80 wins over strain (the warning colour)", same(tint("Left Upper Arm"), ZeD.T.warning))
do  -- a wound wins over strain: the scratch's severity, the colour of its dot in the list (the director, Nov 23 2026)
    local sev = data.partSev and data.partSev["Left Hand"]
    check("a wound wins over strain (a scratch: its severity colour)", sev ~= nil and sev ~= "ok" and same(tint("Left Hand"), ZeD.T[sev == "critical" and "danger" or sev]), sev)
end
check("care alone is no wound (bandage, pain, stitches): the strain tint", same(tint("Right Hand"), ZeD.T.strainMinor))
check("heavy at 95% health: the heavy tint", same(tint("Left Upper Leg"), ZeD.T.strainHeavy))
check("an unstrained healthy part: no tint", tint("Head") == nil)
check("the tint draws at the figure's alpha (0.65)", tint("Right Forearm") and tint("Right Forearm").a == 0.65)
-- another mod's line on a strained part: a wound shows
if H.figureColor then
    local d2 = { partStrain = { X = 2 }, partWound = { X = true } }
    check("figureColor: a part marked wounded keeps its health colour", same(H.figureColor(d2, "X", 100), ZeD.T.positive))
    d2.partWound = {}
    check("figureColor: strained and not wounded: the tint", same(H.figureColor(d2, "X", 100), ZeD.T.strainHeavy))
    check("woundShows: another mod's line is a wound", H.woundShows and H.woundShows({}, 100, { { text = "x" } }) == true)
    check("woundShows: care alone is not", H.woundShows and H.woundShows({ { care = true } }, 100, nil) == false)
end

-- ---------------------------------------------------------------------------
section("COUNTS")
check("strainedCount: every part at 5 or more (6)", data.strainedCount == 6, data.strainedCount)
check("strainWorst: heavy", data.strainWorst == 2, data.strainWorst)
-- wounded: Left Hand (scratch), Right Hand (bandage, pain, stitches: conditions that are not strain); not the strain-only parts
check("woundedCount leaves out strain alone (2)", data.woundedCount == 2, data.woundedCount)
check("the strained parts stay in the injury list (6)", data.entries and #data.entries == 6, data.entries and #data.entries)
local strainOnly = H.gatherData and H.gatherData(newPlayer(newBody({ ForeArm_R = { getStiffness = 10 }, ForeArm_L = { getStiffness = 22 } }))) or {}
check("strain alone: no wound counted, 2 strained", strainOnly.woundedCount == 0 and strainOnly.strainedCount == 2,
      tostring(strainOnly.woundedCount) .. "/" .. tostring(strainOnly.strainedCount))

-- ---------------------------------------------------------------------------
section("SUMMARY")
local function summaryOf(d)
    DRAWN = {}
    local y = H.drawSummary(nil, d, 0, 0)
    local texts, dots = {}, {}
    for _, e in ipairs(DRAWN) do
        if e.text then texts[#texts + 1] = e.text end
        if e.dot then dots[#dots + 1] = e.dot end
    end
    return texts, dots, y
end
if H.drawSummary then
    local texts, dots, y = summaryOf(strainOnly)
    check("strain alone: \"No injuries, Muscle Strain: 2\"", texts[1] == "No injuries, Muscle Strain: 2" and #texts == 1, texts[1])
    check("strain alone: the dot in the heavy tint (the worst)", same(dots[1], ZeD.T.strainHeavy))
    check("strain alone: one line, as measured", H.summaryLineCount(strainOnly) == 1 and y == 24)
    texts, dots, y = summaryOf(data)
    check("wounds and strain: \"2 of 17 injured\" first", texts[1] == "2 of 17 injured", texts[1])
    check("wounds and strain: \"Muscle Strain: 6 of 17\" second", texts[2] == "Muscle Strain: 6 of 17", texts[2])
    check("wounds and strain: two lines, as measured", #texts == 2 and H.summaryLineCount(data) == 2 and y == 48, y)
    local calm = H.gatherData(newPlayer(newBody({})))
    texts, dots = summaryOf(calm)
    check("nothing: \"No injuries\" with the good dot", texts[1] == "No injuries" and same(dots[1], ZeD.T.positive), texts[1])
    check("nothing: one line", H.summaryLineCount(calm) == 1)
    local wounded = H.gatherData(newPlayer(newBody({ Head = { scratched = true, getScratchTime = 5 } })))
    texts = summaryOf(wounded)
    check("wounds alone: \"1 of 17 injured\", one line", texts[1] == "1 of 17 injured" and #texts == 1 and H.summaryLineCount(wounded) == 1, texts[1])
    local low = H.gatherData(newPlayer(newBody({ Head = { health = 70 } })))
    texts, dots = summaryOf(low)
    check("low health alone: the old words, the warning dot", texts[1] == "No injuries, low body health" and same(dots[1], ZeD.T.warning), texts[1])
    -- nothing says "injured" with strain alone
    texts = summaryOf(strainOnly)
    check("strain alone never says injured", not tostring(texts[1]):find("injured", 1, true))
end

-- ---------------------------------------------------------------------------
section("WIRING (Health and the medical card only)")
local thermal = readFile(Z .. "ThermalTab.lua") or ""
local equip = readFile(Z .. "EquipmentTab.lua") or ""
local prot = readFile(Z .. "ProtectionTab.lua") or ""
local medic = readFile(Z .. "ObjectCardMedic.lua") or ""
check("the Health figure draws with figureColor", src and src:find("ZeD.HealthTab.tintPart(fig, data, figureName, health)", 1, true) ~= nil)
check("the medical card's figure reads figureColor", medic:find("ZeD.HealthTab.tintPart(fig, d, fname, health)", 1, true) ~= nil)
check("the medical card's summary is drawSummary", medic:find("ZeD.HealthTab.drawSummary(card, d, rx, y)", 1, true) ~= nil)
check("the medical card keeps no health colour of its own", medic:find("local function healthColor", 1, true) == nil)
local function noStrain(s) return not s:find("strainMap", 1, true) and not s:find("strainColor", 1, true)
    and not s:find("strainMinor", 1, true) and not s:find("strainHeavy", 1, true) and not s:find(".strain", 1, true) end
check("Thermal reads no strain and draws no strain tint", noStrain(thermal))
check("Equipment's defense figure draws no strain tint", noStrain(equip))
check("the defense data reads no strain", noStrain(prot))
check("Thermal's figure: its view colour as before (wetness in its own scheme: the director's call 2)", thermal:find('local color = (view.id == "wetness") and ZeD.ThermalTab.wetColor(uiVal) or getThermalColor(uiVal)\n        fig:setPartColor(partName', 1, true) ~= nil)
check("no strainMap left in HealthTab (nothing reads it)", src and not src:find("strainMap", 1, true) and H.strainMap == nil)

-- ---------------------------------------------------------------------------
section("WORDS")
local en = readFile(TR .. "EN/UI.json") or ""
local nl = readFile(TR .. "NL/UI.json") or ""
local ctx = readFile(ROOT .. "ZeDUI/i18n/UI_ZeD.context.md") or ""
check("EN: No injuries, %1: %2", en:find('"UI_ZeD_Health_NoInjuriesStrain": "No injuries, %1: %2"', 1, true) ~= nil)
check("EN: %1: %2 of %3", en:find('"UI_ZeD_Health_StrainOf": "%1: %2 of %3"', 1, true) ~= nil)
local nl1 = nl:match('"UI_ZeD_Health_NoInjuriesStrain": "([^"]*)"')
local nl2 = nl:match('"UI_ZeD_Health_StrainOf": "([^"]*)"')
check("NL: both keys, their own words, every placeholder", nl1 and nl2 and nl1 ~= "No injuries, %1: %2" and nl2 ~= "%1: %2 of %3"
      and nl1:find("%1", 1, true) and nl1:find("%2", 1, true) and nl2:find("%3", 1, true), tostring(nl1) .. " / " .. tostring(nl2))
check("context rows for both keys", ctx:find("| `UI_ZeD_Health_NoInjuriesStrain` |", 1, true) and ctx:find("| `UI_ZeD_Health_StrainOf` |", 1, true))
check("the game's word, not ours", src and src:find('getText("IGUI_health_Stiffness")   -- the game\'s own "Muscle Strain"', 1, true) ~= nil)

section("BONES (the director, Nov 23 2026: the skeleton always easy to see)")
check("the Health figure lifts its tint (boneLift)", fig ~= nil and fig.boneLift == true)
check("the medical card's figure lifts its tint", medic:find("FIG.boneLift = true", 1, true) ~= nil)
local bodyfig = readFile(Z .. "ZeD_BodyFigure.lua") or ""
check("a lifted tint mixes toward white before it multiplies the bone", bodyfig:find("1 - (1 - color.r) * k", 1, true) ~= nil)
local bt = tonumber(bodyfig:match("local BONE_TINT = ([%d%.]+)"))
check("the lift keeps a danger red bone light (BONE_TINT 0.4 to 0.7)", bt and bt >= 0.4 and bt <= 0.7, bt)
do  -- every theme's severity and strain tokens keep a tinted bone at 0.75 of its light (QA, Nov 23 2026: Light's danger)
    local fsrc = bodyfig:match("(function ZeD_BodyFigure%.boneTintK.-\nend)")
    local keep = tonumber(bodyfig:match("local BONE_KEEP = ([%d%.]+)"))
    check("boneTintK is there, BONE_KEEP 0.75", fsrc ~= nil and keep == 0.75, keep)
    if fsrc then
        local env = { ZeD_BodyFigure = {}, math = math }
        local f = loadstring("local BONE_TINT, BONE_KEEP = " .. tostring(bt) .. ", " .. tostring(keep) .. "\n" .. fsrc)
        if f then setfenv(f, env); f() end
        local K = env.ZeD_BodyFigure.boneTintK
        local toks = readFile(ROOT .. "42/media/lua/shared/ZeD/Tokens.lua") or ""
        local n, worst = 0, 1
        for h in toks:gmatch('%a+%s*=%s*hex%("#(%x%x%x%x%x%x)"%)') do
            local c = { r = tonumber(h:sub(1, 2), 16) / 255, g = tonumber(h:sub(3, 4), 16) / 255, b = tonumber(h:sub(5, 6), 16) / 255 }
            local k = K and K(c) or 1
            local L = 0.299 * (1 - (1 - c.r) * k) + 0.587 * (1 - (1 - c.g) * k) + 0.114 * (1 - (1 - c.b) * k)
            n = n + 1
            if L < worst then worst = L end
        end
        check("no token tints a bone below 0.75 of its light (" .. n .. " tokens)", K ~= nil and n > 20 and worst >= 0.749, worst)
    end
end
check("a part with nothing to say draws no veil on a boneLift figure", bodyfig:find("elseif self.boneLift then", 1, true) ~= nil)
check("Thermal and Equipment's figures are not lifted", not thermal:find("boneLift", 1, true)
    and not (readFile(Z .. "EquipmentTab.lua") or ""):find("boneLift", 1, true))
print("strain_tint_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
