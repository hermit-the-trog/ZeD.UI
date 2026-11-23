-- ZeDUI/tools/qa/health_treat_footer_sim.lua  (the director, Nov 23 2026): the Health tab becomes a treatment card
-- when there is an injury, with no game running. The director's rules:
--   1  with any injury the middle column (where the exercise info is) lists each injury, worst first; with none the
--      exercise info comes back
--   2  muscle strain is listed there too, a row per strained part, in the game's words (Minor Muscle Strain / Muscle
--      Strain); strain alone shows the list too
--   3  with an injury the game's treatment menu can act on, the footer is treatment: a pop-up of the injured parts
--      (worst first, as the exercise pop-up) and Treat (where Start is), which opens the game's menu for the picked
--      part (ZeD.HealthTab.treat, as a click on the figure does); no time step
--   4  strain alone keeps the exercise footer; a part with strain alone is not in the Treat pop-up
--   5  with no injury the footer is the exercise's, as before
-- The REAL HealthTab.lua runs on Lua 5.1 stubs of the body (17 parts) and the drawing library. It checks:
--   NONE     no injury: no rows, the exercise footer, the column draws the exercise's info, Start in the band
--   STRAIN   strain alone: strain rows in the game's words, heavy first; no part to treat; the exercise footer
--   WOUND    a wound and strain: wounds worst first, then strain; the Treat pop-up holds the treatable parts only;
--            the treatment footer: Treat where Start is, no time step, the box names the picked part
--   PICK     the worst is picked until one is picked; the list's rows are the parts; a pick by the mouse and its
--            row ids; the picked part heals: back to the worst
--   TREAT    treatSelected calls ZeD.HealthTab.treat with that part's BodyPart, anchored at the button; a press on
--            Treat waits for the button to come up, then opens it
--   MEASURE  the column's reserved room is the list's height; the layout is kept between frames and reads
--   SWITCH   an open list is shut when the footer changes kind
--   WIRING   the pad's stops in ZeD_CharacterWindow (ids, the same pattern as the exercise picker)
--   WORDS    the new keys in EN and NL UI.json and the translators' context file
-- What it can't show: the card on screen and the game's menu (QA's hg_injury / hg_treat in game).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/health_treat_footer_sim.lua
-- It prints FAIL lines and a last line "health_treat_footer_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]health_treat_footer_sim%.lua$", "")
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
local WORDS = { IGUI_health_Stiffness = "Muscle Strain", IGUI_health_MinorStiffness = "Minor Muscle Strain",
    IGUI_health_Scratch = "Scratch", IGUI_health_Bleeding = "Bleeding", IGUI_health_Bandaged = "Bandaged",
    IGUI_health_DeepWound = "Deep Wound", IGUI_health_ok = "OK", IGUI_health_Slight_damage = "Slight damage",
    IGUI_FitnessRegularity = "Regularity", IGUI_FitnessTime = "Time (minutes)", IGUI_Squats = "Squats" }
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
local NOW = 100000
getTimestampMs = function() return NOW end
local MOUSE_DOWN = false
isMouseButtonDown = function() return MOUSE_DOWN end
Perks = { Doctor = "Doctor" }
MoodleType = { ENDURANCE = "E", HEAVY_LOAD = "H", PAIN = "P" }
ISHealthPanel = { cheat = false }
ISTimedActionQueue = { getTimedActionQueue = function() return nil end }
FitnessExercises = { exercisesType = { squats = { type = "squats", tooltip = "Improves fitness when performed regularly", stiffness = "legs" } } }
local PARTS = { "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin", "UpperArm_L", "UpperArm_R", "ForeArm_L",
    "ForeArm_R", "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }
BodyPartType = { getDisplayName = function(t) return "Part " .. tostring(t) end, ToString = function(t) return tostring(t) end }
for _, n in ipairs(PARTS) do BodyPartType[n] = n end
local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end

local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end
ZeD_BodyFigure = {}
function ZeD_BodyFigure.woundsFrom() return nil end
function ZeD_BodyFigure.skinToneOf() return 0 end

-- what the drawing library was asked to draw
local DRAWN = {}
local function rec(e) DRAWN[#DRAWN + 1] = e end
local function texts()
    local out = {}
    for _, e in ipairs(DRAWN) do if e.text then out[#out + 1] = e.text end end
    return out
end
local function has(list, s) for _, v in ipairs(list) do if v == s then return true end end return false end

ZeD = {
    T = { px = function(n) return n end, scale = 1,
          sp = { sm = 10, xs = 6, rowGap = 4, afterGroove = 8, afterLine = 8, scrollbarW = 12 },
          fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", buttonH = 20, fillBarH = 6,
          text = col(1, 1, 1), textSec = col(0.7, 0.7, 0.7), textHead = col(1, 1, 1), warningText = col(1, 1, 0),
          positive = col(0, 1, 0), warning = col(1, 1, 0), danger = col(1, 0, 0), accent = col(0, 0, 1),
          strainMinor = col(0.8, 0.7, 0.95), strainHeavy = col(0.55, 0.25, 0.8) },
    TM = { getFontHeight = function() return 14 end,
           MeasureStringX = function(_, f, s) return #tostring(s or "") * 7 end },
    logOnce = function() end,
    textCase = function(s) return s end,
    partLabel = function(s) return s end,
}
ZeD.TM.MeasureStringX = function(_, f, s) return #tostring(s or "") * 7 end
ZeD.tr = function(k, ...) return getText(k, ...) end
-- a word wrap at 7 px a letter
local function wrapText(text, font, maxW)
    local out, line = {}, ""
    for word in tostring(text):gmatch("%S+") do
        local try = (line == "") and word or (line .. " " .. word)
        if #try * 7 > maxW and line ~= "" then out[#out + 1] = line; line = word else line = try end
    end
    out[#out + 1] = line
    return out
end
ZeD.Atoms = {
    wrapText = wrapText,
    drawDividerH = function() end,
    drawStatusDot = function(p, x, y, c) rec({ dot = c, x = x, y = y }) end,
    drawBody = function(p, s, x, y) rec({ text = s, x = x, y = y }) end,
    drawSecondary = function(p, s, x, y) rec({ text = s, x = x, y = y }) end,
    drawFillBar = function() end,
    mouseIn = function() return false end,
    padHelp = function() end,
    statusColor = function() return col(0, 1, 0) end,
    pctText = function(f) return math.floor(f * 100) .. "%" end,
    drawTextRight = function() end,
}
local BAND = {}
ZeD.Molecules = {
    layoutZoneA = function(x, y, w) return { rightW = math.floor(w / 2), rightX = x + math.floor(w / 2), rightY = y } end,
    bandH = function() return 30 end,
    buttonW = function(s) return #s * 7 + 16 end,
    popupMenuW = function(s) return #s * 7 + 20 end,
    popupListH = function(n) return 20 * n end,
    drawBand = function(p, x, y, w, spec)
        BAND.buttons = {}
        for _, b in ipairs(spec.buttons or {}) do BAND.buttons[#BAND.buttons + 1] = { label = b.label, id = b.id, disabled = b.disabled } end
    end,
    drawPopupMenu = function(p, x, y, w, h, label) BAND.box = label end,
    drawSortMenuList = function(p, x, y, modes, active, hover, o)
        local zs = {}
        for i, m in ipairs(modes) do zs[i] = { id = m.id, x = x, y = y + (i - 1) * 20, w = 100, h = 20 } end
        BAND.list, BAND.active = modes, active
        return 100, 20 * #modes, zs
    end,
    drawButton = function() end,
    figureZoneH = function(L, rightH) return rightH end,
    drawFillBar = function() return 6 end,
    drawStatRowDot = function() return 18 end,
    drawTag = function(p, x, y, label) rec({ tag = label, x = x, y = y }) end,
}

local src = readFile(Z .. "HealthTab.lua")
check("HealthTab.lua is read", src ~= nil)
local fn, err = loadstring(src or "", "=HealthTab.lua")
check("HealthTab.lua loads", fn ~= nil, err)
if fn then fn() end
local H = ZeD.HealthTab or {}

-- a body: parts by name with a state table each (nil getters read 0 or false); parts keeps the BodyPart objects
local function newBody(states)
    local parts, byName = {}, {}
    for i, n in ipairs(PARTS) do
        local s = states[n] or {}
        parts[i] = setmetatable({ part = n }, { __index = function(_, k)
            if k == "getType" then return function() return n end end
            if k == "getHealth" then return function() return s.health or 100 end end
            return function() local v = s[k]; if v == nil then return 0 end; return v end
        end })
        byName[n] = parts[i]
        for _, flag in ipairs({ "bitten", "bleeding", "deepWounded", "isInfectedWound", "haveBullet", "haveGlass",
                                "scratched", "isCut", "isNeedBurnWash", "bandaged", "stitched" }) do
            if s[flag] == nil then s[flag] = false end
        end
    end
    local list = jlist(parts)
    return { getBodyParts = function() return list end, getOverallBodyHealth = function() return 100 end, byName = byName }
end
local function newPlayer(body)
    return { getBodyDamage = function() return body end, getPerkLevel = function() return 0 end,
             isFemale = function() return false end, getPlayerNum = function() return 0 end,
             getMoodles = function() return { getMoodleLevel = function() return 0 end } end,
             getVariableBoolean = function() return false end, isSittingOnFurniture = function() return false end,
             getVehicle = function() return nil end, isClimbing = function() return false end,
             getInventory = function() return { contains = function() return true end } end,
             getFitness = function() return { getRegularity = function() return 40 end, init = function() end } end }
end
-- a window on a player, as the Character window gives the tab, with a fresh read
local PANEL = { name = "content panel" }
function PANEL:drawText(s, x, y) rec({ text = s, x = x, y = y }) end
function PANEL:drawRect() end
function PANEL:setStencilRect() end
function PANEL:clearStencilRect() end
local function newWin(states)
    local body = newBody(states)
    local p = newPlayer(body)
    local win = { _playerObj = p, _healthContentPanel = PANEL }
    win._healthCache = H.gatherData(p)
    return win, body, p
end
local function names(rows) local out = {} for i, r in ipairs(rows) do out[i] = r.name end return table.concat(out, ",") end
local function drawHeader(win)
    DRAWN = {}
    H.footerMode(win)
    return H._renderHeader(PANEL, win, win._healthCache, 0, 0, 200)
end
local function drawBand(win)
    BAND = {}
    H._renderBand(PANEL, win, 0, 300, 400)
end

check("the new functions are on ZeD.HealthTab", H.injuryList and H.treatParts and H.footerMode and H.selectedTreatPart
      and H.treatSelected and H.pickTreatPart and H._renderInjuryInfo)

-- ---------------------------------------------------------------------------
section("NONE")
local win = newWin({})
check("no injury: no rows", #H.injuryList(win._healthCache) == 0)
check("no injury: the exercise footer", H.footerMode(win) == "exercise" and win._healthFooterMode == "exercise")
check("no injury: no part to treat", H.selectedTreatPart(win) == nil and H.treatSelected(win) == false)
drawHeader(win)
check("no injury: the column draws the exercise's info", win._healthMiddle == "exercise" and win._healthInfoShown == "squats",
      tostring(win._healthMiddle) .. "/" .. tostring(win._healthInfoShown))
local function starts(list, p) for _, v in ipairs(list) do if tostring(v):sub(1, #p) == p then return true end end return false end
check("no injury: the exercise's words are drawn", starts(texts(), "Improves"))
drawBand(win)
check("no injury: Start in the band", BAND.buttons and BAND.buttons[1] and BAND.buttons[1].label == "Start" and BAND.buttons[1].id == "start")
check("no injury: the exercise box", BAND.box == "Exercise: Squats", BAND.box)
check("no injury: the time step keeps its keys", win._healthBand and win._healthBand.dec.w == 20 and win._healthBand.inc.w == 20)
check("the injury list takes a player too", #H.injuryList(newPlayer(newBody({ Head = { scratched = true } }))) == 1)

-- ---------------------------------------------------------------------------
section("STRAIN")
win = newWin({ ForeArm_R = { getStiffness = 10 }, UpperArm_L = { getStiffness = 30 } })
local rows = H.injuryList(win._healthCache)
check("strain alone: a row per strained part, heavy first", names(rows) == "Left Upper Arm,Right Forearm", names(rows))
check("strain alone: strain rows, not treatable", rows[1] and not rows[1].treat and rows[1].strainLv == 2 and rows[2] and rows[2].strainLv == 1)
check("strain alone: no part to treat", #H.treatParts(win._healthCache) == 0)
check("strain alone: the exercise footer", H.footerMode(win) == "exercise")
drawHeader(win)
check("strain alone: the column lists the strain", win._healthMiddle == "injuries" and win._healthInjuryShown == 2,
      tostring(win._healthMiddle) .. "/" .. tostring(win._healthInjuryShown))
local tagWords = {}
for _, e in ipairs(DRAWN) do if e.tag then tagWords[#tagWords + 1] = e.tag end end
check("strain alone: in the game's words", has(tagWords, "Muscle Strain") and has(tagWords, "Minor Muscle Strain"), table.concat(tagWords, ","))
check("strain alone: the part names are drawn", has(texts(), "Left Upper Arm") and has(texts(), "Right Forearm"))
check("strain alone: no exercise info this frame", win._healthInfoShown == nil and not starts(texts(), "Improves"))
local dots = {}
for _, e in ipairs(DRAWN) do if e.dot then dots[#dots + 1] = e.dot end end
local function hasDot(c) for _, d in ipairs(dots) do if d == c then return true end end return false end
check("strain alone: the rows' dots in the strain tints", hasDot(ZeD.T.strainHeavy) and hasDot(ZeD.T.strainMinor))
drawBand(win)
check("strain alone: Start stays", BAND.buttons and BAND.buttons[1] and BAND.buttons[1].label == "Start")

-- ---------------------------------------------------------------------------
section("WOUND")
local states = {
    Hand_L     = { scratched = true, getScratchTime = 5 },                         -- warning
    Head       = { bleeding = true, health = 60 },                                 -- danger
    Torso_Upper = { bleeding = true, health = 40 },                                -- danger, lower health: first
    UpperArm_L = { bandaged = true, getBandageLife = 1 },                          -- care only: listed, treatable
    ForeArm_R  = { getStiffness = 25 },                                            -- strain only
    Foot_L     = { health = 70 },                                                  -- low health alone: no row
}
local body
win, body = newWin(states)
rows = H.injuryList(win._healthCache)
check("wounds worst first, then strain", names(rows) == "Upper Torso,Head,Left Hand,Left Upper Arm,Right Forearm", names(rows))
local treat = H.treatParts(win._healthCache)
check("the Treat pop-up: the treatable parts only, worst first", names(treat) == "Upper Torso,Head,Left Hand,Left Upper Arm", names(treat))
check("a wound and strain: the treatment footer", H.footerMode(win) == "treat" and win._healthFooterMode == "treat")
check("the rows are kept on the read", H.injuryList(win._healthCache) == rows and H.treatParts(win._healthCache) == treat)
drawHeader(win)
check("the column lists every row", win._healthMiddle == "injuries" and win._healthInjuryShown == 5)
local tx = texts()
local function idx(s) for i, v in ipairs(tx) do if v == s then return i end end return 0 end
check("the column draws them in order", idx("Upper Torso") > 0 and idx("Upper Torso") < idx("Head") and idx("Head") < idx("Left Hand")
      and idx("Left Hand") < idx("Left Upper Arm") and idx("Left Upper Arm") < idx("Right Forearm"))
drawBand(win)
check("the treatment band: Treat where Start is", BAND.buttons and #BAND.buttons == 1 and BAND.buttons[1].label == "Treat"
      and BAND.buttons[1].id == "treat" and not BAND.buttons[1].disabled)
check("the treatment band: the box names the worst part", BAND.box == "Injury: Upper Torso", BAND.box)
local bz = win._healthBand
check("the treatment band: no time step (its rects take no press)", bz.dec.w == 0 and bz.inc.w == 0)
check("the treatment band: Treat's rect at the right", bz.start.w > 0 and bz.start.x > bz.box.x)

-- ---------------------------------------------------------------------------
section("PICK")
check("the worst is picked first", H.selectedTreatPart(win) and H.selectedTreatPart(win).name == "Upper Torso")
-- the mouse: the box opens the list; the list's rows are the parts, the picked one active
H.onClick(win, bz.box.x + 1, bz.box.y + 1)
check("the box opens the list", win._healthMenuOpen == true)
BAND = {}
H._renderMenu(PANEL, win)
check("the list holds the parts to treat, worst first", BAND.list and #BAND.list == 4 and BAND.list[1].id == "Upper Torso"
      and BAND.list[4].id == "Left Upper Arm", BAND.list and #BAND.list)
check("the picked part is the active row", BAND.active == "Upper Torso", BAND.active)
local zone = nil
for _, z in ipairs(win._healthMenuZones or {}) do if z.id == "Left Hand" then zone = z end end
check("the list's rows are stamped", zone ~= nil)
if zone then H.onClick(win, zone.x + 1, zone.y + 1) end
check("a press on a row picks it and shuts the list", win._healthTreatSel == "Left Hand" and not win._healthMenuOpen
      and win._healthReturnToMenu == true)
check("the exercise pick is untouched", H.selectedExercise(win) == "squats")
check("the picked part is the selection", H.selectedTreatPart(win).name == "Left Hand")
drawBand(win)
check("the box names the picked part", BAND.box == "Injury: Left Hand", BAND.box)
-- the picked part heals: a new read without it
states.Hand_L.scratched = false   -- (the same state table the body reads)
win._healthCache = H.gatherData(win._playerObj)
check("healed: back to the worst", H.selectedTreatPart(win) and H.selectedTreatPart(win).name == "Upper Torso"
      and win._healthTreatSel == nil)
win._healthTreatSel = "Right Forearm"   -- (strain alone is never a pick)
check("a strained part is no pick: the worst", H.selectedTreatPart(win).name == "Upper Torso")

-- ---------------------------------------------------------------------------
section("TREAT")
local CALL = nil
local realTreat = H.treat
H.treat = function(patient, doctor, bp, anchor, rx, ry, blocking)
    CALL = { patient = patient, doctor = doctor, bp = bp, anchor = anchor, rx = rx, ry = ry, blocking = blocking }
end
H.pickTreatPart(win, "Head")
drawBand(win)
check("treatSelected asks for the menu", H.treatSelected(win) == true and CALL ~= nil)
check("treatSelected: that part's BodyPart, the patient's own", CALL and CALL.bp == body.byName.Head and CALL.patient == win._playerObj
      and CALL.doctor == nil and CALL.blocking == nil)
check("treatSelected: anchored at Treat in the content panel", CALL and CALL.anchor == PANEL and CALL.rx == win._healthBand.start.x
      and CALL.ry == win._healthBand.start.y)
-- a press on Treat waits for the button to come up (the release never lands on the menu)
CALL = nil
MOUSE_DOWN = true
H.onClick(win, win._healthBand.start.x + 1, win._healthBand.start.y + 1)
check("a press on Treat marks it, opens nothing yet", win._healthPress and win._healthPress.treat == true and CALL == nil)
MOUSE_DOWN = false
-- the pending press opens from the render (its first step, openPendingPress): the tab's render, on stubs
do
    local w2 = win
    w2._healthScroll = { visible = false, setScrollPos = function() end, draw = function() end, setBarSize = function() end }
    w2._healthFigureExpanded = false
    ZeD.TabFill = { begin = function() end, block = function() return 0 end, onClick = function() return false end }
    H.gatherFill = function() return { moodles = {}, strain = {}, exercises = {}, rows = { moodles = {}, fitness = {}, regularity = {}, strain = {} } } end
    ZeD.Molecules.getTabPad = function() return 8 end
    ZeD.Molecules.getTabHeaderH = function() return 37 end
    ZeD.Molecules.getTabPadTop = function() return 8 end
    ZeD.Molecules.drawTabHeader = function() end
    ZeD.T.stripe = col(0, 0, 0)
    ZeD.Focus = { mark = function() return false end }
    local okRender, errRender = pcall(H.render, PANEL, w2, 0, 0, 400, 600)
    check("the tab renders in treat mode", okRender, errRender)
end
check("the button up: Treat opens the picked part's menu", CALL and CALL.bp == body.byName.Head, CALL and CALL.bp and CALL.bp.part)
check("the press is spent", win._healthPress == nil)
H.treat = realTreat

-- ---------------------------------------------------------------------------
section("MEASURE")
win = newWin(states)
H.footerMode(win)
local mh = H._measureExerciseInfo(win, 400, win._healthCache)
local lay = win._healthInjMeas and win._healthInjMeas.lay
check("the reserve is the list's height", lay and mh == 1 + 8 + lay.h and win._healthInfoH == lay.h, mh)
drawHeader(win)
check("what the column draws is what was reserved", win._healthInfoUsedH == win._healthInfoH, tostring(win._healthInfoUsedH) .. "/" .. tostring(win._healthInfoH))
local firstLay = win._healthInjLay and win._healthInjLay.lay
drawHeader(win)
check("the layout is kept between frames", win._healthInjLay and win._healthInjLay.lay == firstLay)
win._healthCache = H.gatherData(win._playerObj)   -- a new read, the same words
drawHeader(win)
check("the layout is kept over a read with the same words", win._healthInjLay.lay == firstLay)
local exOnly = newWin({})
local exH = H._measureExerciseInfo(exOnly, 400, exOnly._healthCache)
check("no injury: the reserve is the exercise's again", exH > 0 and exOnly._healthInjMeas == nil)
-- the zone's measure counts the list: a long list reserves more than the exercise
local many = {}
for _, n in ipairs(PARTS) do many[n] = { scratched = true, getScratchTime = 5 } end
local big = newWin(many)
local zoneBig = H._measureZoneA(big._healthCache, 400, big)
local zoneEx = H._measureZoneA(exOnly._healthCache, 400, exOnly)
check("the zone's measure grows with a long list", zoneBig > zoneEx, tostring(zoneBig) .. " > " .. tostring(zoneEx))

-- ---------------------------------------------------------------------------
section("SWITCH")
win = newWin({ Head = { scratched = true } })
H.footerMode(win)
H.openMenu(win)
-- the wound heals while the list is open: the render shuts the list
win._healthCache = nil
win._playerObj = newPlayer(newBody({}))
win._healthScroll = { visible = false, setScrollPos = function() end, draw = function() end, setBarSize = function() end }
win._healthFigureExpanded = false
local okSw, errSw = pcall(H.render, PANEL, win, 0, 0, 400, 600)
check("the render runs", okSw, errSw)
check("healed: the exercise footer, the list shut", win._healthFooterMode == "exercise" and not win._healthMenuOpen)

-- ---------------------------------------------------------------------------
section("WIRING")
local cw = readFile(Z .. "ZeD_CharacterWindow.lua") or ""
check("the pad: the box is health:treatPart", cw:find('id = "health:treatPart", bandStop = true', 1, true) ~= nil)
check("the pad: Treat is health:treat and calls treatSelected",
      cw:find('id = "health:treat", bandStop = true', 1, true) ~= nil and cw:find("H.treatSelected(w)", 1, true) ~= nil)
check("the pad: the list's rows are health:treatRow:<part>, A picks", cw:find('"health:treatRow:"', 1, true) ~= nil
      and cw:find("H.pickTreatPart(w, el.menuRowId)", 1, true) ~= nil)
check("the pad: the box takes the focus back after a pick, as the exercise's",
      cw:find('band[i].id == "health:exercise" or band[i].id == "health:treatPart"', 1, true) ~= nil)
check("the pad: the mode is the render's", cw:find('win._healthFooterMode == "treat"', 1, true) ~= nil)

-- ---------------------------------------------------------------------------
section("WORDS")
local en = readFile(TR .. "EN/UI.json") or ""
local nl = readFile(TR .. "NL/UI.json") or ""
local ctx = readFile(ROOT .. "ZeDUI/i18n/UI_ZeD.context.md") or ""
local KEYS = { UI_ZeD_Health_Treat = "Treat", UI_ZeD_Health_TreatPick = "Injury: %1",
               UI_ZeD_Health_HelpTreat = "Show the treatments for %1.", UI_ZeD_Health_HelpTreatPick = "Choose the part to treat." }
for k, v in pairs(KEYS) do
    check("EN: " .. k, en:find('"' .. k .. '": "' .. v .. '"', 1, true) ~= nil)
    local n = nl:match('"' .. k .. '": "([^"]*)"')
    check("NL: " .. k .. " in its own words, every placeholder", n and n ~= v and (not v:find("%1", 1, true) or n:find("%1", 1, true)), n)
    check("context row: " .. k, ctx:find("| `" .. k .. "` |", 1, true) ~= nil)
end

print("health_treat_footer_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
