-- ZeDUI/tools/qa/tab_search_sim.lua  (Nov 11 2026, Build; punch list 171, with the Transcribe key's pad order from 172):
-- the Find field on the Character window's Skills and Equipment tabs, with no game running. It loads the real
-- TabFind.lua, SkillsTab.lua, EquipDoll.lua and EquipmentTab.lua over stubs of the game and of ZeD's library, and
-- shows:
--   * the matching: skill names, a group name keeping its whole group, the Training materials rows (by the skill's
--     name or with its group); worn item names, slot words, the body parts an item covers (and which ones);
--   * the tabs as drawn: rows that don't match dimmed in place (none hidden), the matched letters underlined, the
--     count in the heading, the "covers ..." line under an item matched by a body part, the Defense block hidden
--     while searching and back after, the Doll view's boxes dimmed but for the matching ones, the empty result
--     with its Clear key and no row stops behind it;
--   * the text: each tab its own, kept across tab switches (the field shows on its own tab only), gone with the
--     window (a new window starts empty; the pad keyboard on a field is put away on close); Clear empties it;
--   * the controller: A on the field opens the pad keyboard holding the controller (a pad bound to the player or
--     not), the hand on the field under it; RT (Accept) lands the hand on the first match, a clear on the field,
--     both taking the window's focus into the tab from wherever it was (the tab strip); the Skills tab's Up and Down order at its top: Up from the
--     top skill rows lands on the Transcribe key (a mod's key line) before the heading, Up from the key on the
--     Find field, Down from the field or the disclosure on the key; with no key everything moves as before.
--   * the Nov 12 review's findings (section 8, each check failed before its fix): the field lets go of the game's
--     keyboard after B, on Enter, hidden and on close; the help line's A Type / X Clear; the doll's outfit read again
--     while nothing matches; a belt hook matched in neither view; the Equipped group headers' height and the belt's
--     one heading; Training materials in name order with room for the names; a row tag measured as drawn; an extra's
--     height asked once a frame; no new tables or strings each frame while searching; the empty result's and the
--     Worst zone's words.
-- What it can't show is how it looks and the pad in the game: ZeDUI/tools/qa/zedqa_tab_search.lua.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/tab_search_sim.lua
-- It prints FAIL lines and a last line "tab_search_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]tab_search_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end

-- ---------------------------------------------------------------------------
-- THE STUBS: the game
-- ---------------------------------------------------------------------------
local TEXT = {
    IGUI_XP_Skills = "Skills",
    UI_ZeD_Equip_Equipped = "Equipped",
    UI_ClothingType_Hat = "Hat", UI_ClothingType_Hands = "Hands", UI_ClothingType_Pants = "Pants",
    UI_ClothingType_Socks = "Socks", UI_ClothingType_Shoes = "Shoes", UI_ClothingType_Belt = "Belt",
    UI_ZeD_Equip_Outer = "Outer", UI_ZeD_Equip_Inner = "Inner",
    IGUI_PrimaryTooltip = "Primary Hand", IGUI_SecondaryTooltip = "Secondary Hand",
    UI_ZeD_Doll_Hands = "Hands", UI_ZeD_Doll_Main = "Main hand", UI_ZeD_Doll_Off = "Off hand",
    UI_ClothingType_Mask = "Mask", UI_ClothingType_Ears = "Ears", UI_ClothingType_Scarf = "Scarf",
    UI_ClothingType_Vest = "Vest", UI_ClothingType_Underwear = "Underwear", UI_ClothingType_Neck = "Neck",
    UI_ZeD_Equip_Eyewear = "Eyewear", UI_ZeD_Equip_Wrist = "Wrist", UI_ZeD_Equip_Ring = "Ring", UI_ZeD_Equip_Arms = "Arms",
    UI_ZeD_Equip_Shoulder = "Shoulder", UI_ZeD_Equip_KneeLeg = "Knee + leg", UI_ZeD_Equip_BackBag = "Back",
    UI_ZeD_Find_SkillsHint = "Find a skill", UI_ZeD_Find_EquipHint = "Find worn, slot, body part",
    UI_ZeD_Find_Count = "%1 of %2", UI_ZeD_Find_SkillsNone = 'Nothing on the Skills tab matches "%1".',
    UI_ZeD_Find_SkillsLooks = "The Find field looks at skills, their groups and the training books.",
    UI_ZeD_Find_EquipNone = 'Nothing on the Equipment tab matches "%1".',
    UI_ZeD_Find_EquipLooks = "The Find field looks at worn items, slots and the body parts they cover.",
    UI_ZeD_Find_Clear = "Clear", UI_ZeD_Find_Covers = "covers %1", UI_ZeD_Inv_PromptType = "Type",
}
local function tr(k, ...)
    local s = TEXT[k] or k
    local args = { ... }
    s = string.gsub(s, "%%(%d)", function(n) local v = args[tonumber(n)]; return v ~= nil and tostring(v) or "" end)
    return s
end
getText = tr
local NOW = 1000
getTimestampMs = function() NOW = NOW + 1; return NOW end
getSoundManager = function() return { playUISound = noop } end
JoypadState = { players = {} }
updateJoypadFocus = noop
require = noop
Perks = { None = "None" }

-- the game's text field and ZeD's search field, as far as TabFind uses them
local function entry()
    local e = { text = "", focused = false }
    e.getText = function(self) return self.text end
    e.getInternalText = e.getText
    e.setText = function(self, t) self.text = t end
    e.focus = function(self) self.focused = true end
    e.unfocus = function(self) self.focused = false end
    e.isFocused = function(self) return self.focused end
    e.getWidth = function() return 100 end
    e.setWidth = noop
    return e
end
ZeD_SearchField = {}
ZeD_SearchField.__index = ZeD_SearchField
function ZeD_SearchField:derive(name)
    local c = setmetatable({}, { __index = self })
    c.__index = c
    c.Type = name
    return c
end
function ZeD_SearchField:new(x, y, w, ph)
    local o = setmetatable({ x = x, y = y, width = w, height = 20, placeholder = ph, visible = true, iconAreaW = 24 }, self)
    o.input = entry()
    o._lastText = ""
    return o
end
function ZeD_SearchField:initialise() end
function ZeD_SearchField:setVisible(v) self.visible = v end
function ZeD_SearchField:isVisible() return self.visible end
function ZeD_SearchField:getX() return self.x end
function ZeD_SearchField:getY() return self.y end
function ZeD_SearchField:getWidth() return self.width end
function ZeD_SearchField:getHeight() return self.height end
function ZeD_SearchField:setX(v) self.x = v end
function ZeD_SearchField:setY(v) self.y = v end
function ZeD_SearchField:setWidth(v) self.width = v end
function ZeD_SearchField:setHeight(v) self.height = v end
function ZeD_SearchField:getText() return self.input:getText() end
function ZeD_SearchField:clear() self.input:setText(""); self._lastText = "" end
-- the field's own poll (ZeD_SearchField:update): a typed change reaches onFilter
local function typeInto(f, text)
    f.input:setText(text)
    if text ~= f._lastText then f._lastText = text; if f.onFilter then f.onFilter(f, text) end end
end

ZeD_BodyFigure = { new = function()
    return { initialise = noop, loadTextures = noop, setSex = noop, setPartColor = noop,
             drawAt = function(self) self.drawn = (self.drawn or 0) + 1 end, getPartRects = function() return {} end }
end }

-- ---------------------------------------------------------------------------
-- THE STUBS: ZeD's library
-- ---------------------------------------------------------------------------
local COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local ACCENT = { r = 0.9, g = 0.6, b = 0.1, a = 1 }
local BASE = { r = 0.1, g = 0.1, b = 0.12, a = 0.92 }
local NUM = { scale = 1, rowH = 24, inputH = 20, buttonH = 22, selectionA = 0.3, disabledAlpha = 0.4, hair = 1 }
local T = setmetatable({ px = function(n) return n end, accent = ACCENT, base = BASE,
    sp = setmetatable({ tabHeaderH = 37, scrollbarW = 8 }, { __index = function() return 4 end }) },
    { __index = function(_, k)
        if NUM[k] then return NUM[k] end
        if type(k) == "string" and k:match("^font.*H$") then return 14 end
        return COLOR
    end })
local buttons = {}
local function zero() return 0 end
ZeD = {
    T = T,
    TM = { getFontHeight = function() return 14 end, MeasureStringX = function(_, _, s) return #tostring(s) * 7 end,
           MeasureStringY = function() return 14 end },
    tr = tr, trBare = function(k) return k end, trTestOn = function() return false end,
    btnCase = function(s) return s end, textCase = function(s) return s end, upper = string.upper,
    logOnce = function(k, e) print("logOnce " .. tostring(k) .. ": " .. tostring(e)) end,
    Text = { wordsEpoch = function() return 1 end, measureEpoch = function() return 1 end },
    Settings = { equipViewOption = { getValue = function() return VIEW end } },
}
VIEW = 1
ZeD.Atoms = setmetatable({
    SWATCH_W = 10, SWATCH_H = 8,
    lineJo = function() return nil end,   -- (the dashed edges rect by rect)
    truncateText = function(s) return s end,
    mouseIn = function() return false end,
    textCase = function(s) return s end,
    wrapText = function(s) return { s } end,
    drawSegFill = function() return false end,
    drawFillBar = function() return false end,
    statusColor = function() return COLOR end,
    fillBarCompactH = function() return 8 end,
    rowBarW = function() return 60 end,
    fillBarMinW = function() return 21 end,
    safeGet = function(o, m, ...)
        if not o then return nil end
        local f = o[m]
        if type(f) ~= "function" then return nil end
        local ok, r = pcall(f, o, ...)
        if ok then return r end
        return nil
    end,
}, { __index = function() return zero end })
ZeD.Molecules = setmetatable({
    getTabHeaderH = function() return 37 end, getTabPad = function() return 8 end, getTabPadTop = function() return 8 end,
    drawSectionHeader = function() return 20 end, drawTabHeader = function() return 37 end,
    buttonW = function(s) return math.max(#s * 7 + 20, 60) end,
    drawButton = function(_, x, y, w, h, text, variant, pressed, colors, opts)
        buttons[#buttons + 1] = { x = x, y = y, w = w, h = h, text = text, variant = variant, opts = opts }
    end,
    layoutZoneA = function() return { figX = 0, figY = 0, rightX = 100, rightY = 0, rightW = 200 } end,
}, { __index = function() return zero end })
ZeD.ProtectionTab = {
    gatherData = function() return { isFemale = false, partDefense = {}, grade = "B", avgBiteDef = 10,
        worstPart = { name = "Head", biteDef = -1 }, bestPart = { name = "Head", biteDef = -1 }, totalGarments = 7, partStats = {} } end,
    _measureRightColumn = function() return 100 end,
    tierColor = function() return COLOR end, gradeColor = function() return COLOR end,
    protectionColorForDef = function() return COLOR end,
    ALL_PARTS = {}, PART_TO_FIGURE = {}, FIGURE_TO_PART = {},
}
ZeD.partLabel = function(s) return s end

-- the drawer: records the draws the checks read
local D = { rects = {}, texts = {} }
local panel = {
    drawRect = function(_, x, y, w, h, a, r, g, b) D.rects[#D.rects + 1] = { x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b } end,
    drawRectBorder = noop,
    drawText = function(_, s, x, y) D.texts[#D.texts + 1] = { s = s, x = x, y = y } end,
    drawTextureScaledAspect = noop,
    setStencilRect = noop, clearStencilRect = noop,
    getMouseX = function() return -1000 end, getMouseY = function() return -1000 end,
    getWidth = function() return 480 end, getHeight = function() return 2000 end,
    getAbsoluteX = function() return 0 end, getAbsoluteY = function() return 0 end,
    isMouseOver = function() return false end,
}
local function resetDraws() D.rects, D.texts, buttons = {}, {}, {} end
local function dims() local n = 0 for _, r in ipairs(D.rects) do if r.a == 0.65 and r.r == BASE.r then n = n + 1 end end return n end
local function underlines() local n = 0 for _, r in ipairs(D.rects) do if r.h == 1 and r.r == ACCENT.r and r.a == 1 then n = n + 1 end end return n end
local function drew(pat) for _, t in ipairs(D.texts) do if string.find(t.s, pat, 1, true) then return t end end return nil end
local function drewCount(prefix) local n = 0 for _, t in ipairs(D.texts) do if string.sub(t.s, 1, #prefix) == prefix then n = n + 1 end end return n end

local function scrollState()
    return { scrollPos = 0, visible = false, setBarSize = noop, setScrollPos = function(self, p) self.scrollPos = p end, draw = noop }
end

-- ---------------------------------------------------------------------------
-- LOAD THE REAL FILES
-- ---------------------------------------------------------------------------
dofile(ROOT .. "42/media/lua/client/ZeD/TabFind.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/SkillsTab.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/EquipDoll.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/EquipmentTab.lua")
local F = ZeD.TabFind
check("TabFind loaded", F and F.matchSkills and F.drawHead)

-- ---------------------------------------------------------------------------
-- THE CHARACTER: the mockup's skills and outfit
-- ---------------------------------------------------------------------------
local GROUPS = {
    { "Combat - Firearms", { "Aiming", "Reloading" } },
    { "Combat - Melee", { "Axe", "Long Blade", "Long Blunt", "Maintenance", "Short Blade", "Short Blunt", "Spear" } },
    { "Crafting", { "Blacksmithing", "Carpentry", "Carving", "Cooking", "Electrical", "Glassmaking", "Knapping", "Masonry",
                    "Mechanics", "Pottery", "Tailoring", "Welding" } },
    { "Farming", { "Agriculture", "Animal Care", "Butchering" } },
    { "Survival", { "First Aid", "Fishing", "Foraging", "Tracking", "Trapping" } },
    { "Agility", { "Lightfooted", "Nimble", "Running", "Sneaking" } },
    { "Passive", { "Fitness", "Strength" } },
}
local function skillsData()
    local cats, n = {}, 0
    for _, g in ipairs(GROUPS) do
        local skills = {}
        for _, s in ipairs(g[2]) do skills[#skills + 1] = { name = s, level = 1, xpProgress = 0, boost = 0 }; n = n + 1 end
        cats[#cats + 1] = { name = g[1], skills = skills }
    end
    return { categories = cats, totalSkills = n, totalLevels = n }
end
local TRAINING = {}
for _, s in ipairs({ "Blacksmithing", "Carpentry", "Cooking", "Mechanics", "Tailoring", "Fishing" }) do
    TRAINING[#TRAINING + 1] = { label = s, disp = s, items = { { title = "Vol", volume = "I", status = "missing" } } }
end
local SKILLS_DATA = skillsData()
local realTraining = ZeD.SkillsTab.gatherTrainingData   -- (section 8 runs the real one over the game's books)
ZeD.SkillsTab.gatherData = function() return SKILLS_DATA end
ZeD.SkillsTab.gatherTrainingData = function() return TRAINING end

-- the game's type test, and a count of the Java exceptions a call on a missing method would raise
-- (a caught one is still raised: -debug logs each, and it costs a stack trace)
instanceof = function(o, cls)
    if type(o) ~= "table" then return false end
    if cls == "InventoryItem" then return rawget(o, "_class") ~= nil end
    return rawget(o, "_class") == cls
end
local function part(name) return { getDisplayName = function() return name end } end
local function item(name, parts)
    local ps = {}
    for _, p in ipairs(parts or {}) do ps[#ps + 1] = part(p) end
    return {
        _class = "Clothing",
        getDisplayName = function() return name end, getName = function() return name end,
        getCoveredParts = function() return list(ps) end,
        getCondition = function() return 8 end, getConditionMax = function() return 10 end,
        getBiteDefense = function() return 0 end, getScratchDefense = function() return 0 end,
        getDefForPart = function() return 0 end, getUnequippedWeight = function() return 1 end,
        getPatchesNumber = function() return 0 end,
    }
end
local CAP = item("Baseball Cap", { "Head" })
local JACKET = item("Leather Jacket", { "Upper Torso", "Lower Torso", "Left Upper Arm", "Right Upper Arm" })
local SHIRT = item("T-Shirt", { "Upper Torso", "Lower Torso" })
local GLOVES = item("Leather Gloves", { "Left Hand", "Right Hand" })
local JEANS = item("Jeans", { "Groin", "Left Thigh", "Right Thigh", "Left Shin", "Right Shin" })
local SOCKS = item("Socks", { "Left Foot", "Right Foot" })
local BOOTS = item("Military Boots", { "Left Foot", "Right Foot", "Left Shin", "Right Shin" })
-- held tools: not Clothing, so no getCoveredParts. As on a Java object, reading the missing
-- method gives nil (ZeD.Atoms.safeGet reads it so, safely); calling it raises. ASKED counts the
-- reads, so the sim can show the Find code never touches it.
local ASKED = 0
local NOT_CLOTHING = { __index = function(_, k) if k == "getCoveredParts" then ASKED = ASKED + 1 end return nil end }
local CROWBAR = setmetatable({ _class = "HandWeapon", getDisplayName = function() return "Crowbar" end,
                  getCondition = function() return 8 end, getConditionMax = function() return 10 end }, NOT_CLOTHING)
local TORCH = setmetatable({ _class = "DrainableComboItem", getDisplayName = function() return "Flashlight" end,
                getCondition = function() return 8 end, getConditionMax = function() return 10 end }, NOT_CLOTHING)
local WORN = { { "Base:Hat", CAP }, { "Base:Jacket", JACKET }, { "Base:Tshirt", SHIRT }, { "Base:Hands", GLOVES },
               { "Base:Pants", JEANS }, { "Base:Socks", SOCKS }, { "Base:Shoes", BOOTS } }
local PLAYER = {
    getWornItems = function()
        local t = {}
        for _, w in ipairs(WORN) do
            local loc, it = w[1], w[2]
            t[#t + 1] = { getItem = function() return it end, getLocation = function() return loc end }
        end
        return list(t)
    end,
    getPrimaryHandItem = function() return CROWBAR end,
    getSecondaryHandItem = function() return TORCH end,
    isFemale = function() return false end,
    getPlayerNum = function() return 0 end,
}

local function newWin()
    local w = { _playerObj = PLAYER, playerNum = 0, _skillsScroll = scrollState(), _equipScroll = scrollState(),
                _skillsGridExpanded = true, _activeTab = "skills", _drawerMode = "tab" }
    w._drawerPanel = { children = {}, addChild = function(self, c) self.children[#self.children + 1] = c end }
    return w
end
local function drawSkills(win) resetDraws(); ZeD.SkillsTab.render(panel, win, 0, 0, 480, 2000) end
local function drawEquip(win) resetDraws(); ZeD.EquipmentTab.render(panel, win, 0, 0, 480, 2000) end

-- ===========================================================================
-- 1. THE MATCHING
-- ===========================================================================
do
    local r = F.matchSkills(SKILLS_DATA.categories, TRAINING, F.norm("bla"))
    check("skills 'bla': three kept (Blacksmithing, Long Blade, Short Blade)", r.shown == 3 and r.skill.Blacksmithing
        and r.skill["Long Blade"] and r.skill["Short Blade"], r.shown)
    check("skills 'bla': of 35 in all", r.total == 35, r.total)
    check("skills 'bla': Combat - Melee keeps 2, Farming 0", r.group["Combat - Melee"] == 2 and r.group.Farming == 0)
    check("skills 'bla': the training row by the skill's name (Blacksmithing), not the others",
        r.train.Blacksmithing and not r.train.Carpentry and not r.train.Cooking)
    local c = F.matchSkills(SKILLS_DATA.categories, TRAINING, F.norm("  COMBAT "))
    check("skills 'combat' (any case, spaces trimmed): both combat groups whole", c.shown == 9
        and c.skill.Aiming and c.skill.Spear and c.groupHit["Combat - Melee"], c.shown)
    local cr = F.matchSkills(SKILLS_DATA.categories, TRAINING, F.norm("crafting"))
    check("skills 'crafting': a group name keeps its whole group (12)", cr.shown == 12 and cr.group.Crafting == 12, cr.shown)
    check("skills 'crafting': its skills' training rows come with it", cr.train.Carpentry and cr.train.Cooking
        and cr.train.Tailoring and not cr.train.Fishing)
    local ck = F.matchSkills(SKILLS_DATA.categories, TRAINING, F.norm("cook"))
    check("skills 'cook': Cooking and its books", ck.shown == 1 and ck.train.Cooking and not ck.train.Carpentry)
    local pat = F.matchSkills(SKILLS_DATA.categories, TRAINING, F.norm("("))
    check("a typed pattern character is read as plain text", pat.shown == 0)
    local none = F.matchSkills(SKILLS_DATA.categories, TRAINING, F.norm("piloting"))
    check("skills 'piloting': nothing", none.shown == 0 and none.total == 35)

    check("item by name", F.matchItem("Jeans", "Pants", {}, "jean") == "name")
    check("item by slot words", F.matchItem("Leather Gloves", "Hands", { "Left Hand" }, "hand") == "slot")
    local why, parts = F.matchItem("Socks", "Socks", { "Left Foot", "Right Foot" }, "foot")
    check("item by body part: 'covers' with the parts that hold the text", why == "covers" and parts and #parts == 2
        and parts[1] == "Left Foot" and parts[2] == "Right Foot", why)
    local w2, p2 = F.matchItem("Military Boots", "Shoes", { "Left Foot", "Right Foot", "Left Shin", "Right Shin" }, "left")
    check("item by body part: only the matching parts listed", w2 == "covers" and #p2 == 2 and p2[1] == "Left Foot"
        and p2[2] == "Left Shin")
    check("item: no match", F.matchItem("Crowbar", "Primary Hand", {}, "sock") == nil)
    local asked0 = ASKED
    local inf = F.infoOf(CROWBAR)
    local inf2 = F.infoOf(TORCH)
    check("a held tool with no body parts reads as none", inf.name == "Crowbar" and #inf.parts == 0
        and inf2.name == "Flashlight" and #inf2.parts == 0)
    check("a held tool is never asked for getCoveredParts (no Java exception raised, caught or not)", ASKED == asked0, ASKED - asked0)
    local socks = F.infoOf(SOCKS)
    check("clothing: its body parts in the game's words", #socks.parts == 2 and socks.parts[1] == "Left Foot")
    check("not an item at all: an empty answer, no call made", F.infoOf({}).name == "")
end

-- ===========================================================================
-- 2. THE SKILLS TAB, DRAWN
-- ===========================================================================
local win = newWin()
drawSkills(win)
check("skills, nothing typed: nothing dimmed", dims() == 0, dims())
check("skills, nothing typed: no count", not drew(" of 35"))
check("skills, nothing typed: the field's place in the heading", F.rect(win, "skills") ~= nil)
local fr = F.rect(win, "skills") or {}
check("skills: the field ends 10u from the heading's right edge", fr.x and fr.x + fr.w == 470, fr.x and fr.x + fr.w)
check("skills: the field 200u wide at the full card", fr.w == 200, fr.w)
check("skills: the disclosure's zone stops short of the field (next frame)",
    (function() drawSkills(win); return win._skillsGridZone.w < fr.x end)(), win._skillsGridZone and win._skillsGridZone.w)
local rowsAll = #win._skillRowZones
check("skills: 35 row stops", rowsAll == 35, rowsAll)

-- the window frame makes and shows the field; typing reaches the tab
F.onWindowFrame(win, 480)
local sf = win._findFields and win._findFields.skills
check("skills: the field is made on the drawer and shown", sf ~= nil and sf.visible == true and #win._drawerPanel.children == 1)
check("skills: the field sits at its place", sf and sf.x == fr.x and sf.y == fr.y and sf.width == fr.w)
check("skills: its words are the placeholder", sf and sf.placeholder == "Find a skill")
typeInto(sf, "bla")
drawSkills(win)
local zDim = 35 - 3                                   -- rows not kept
local gDim = 4                                        -- Firearms, Farming, Survival, Agility, Passive minus...
-- (groups with nothing kept: Combat - Firearms, Farming, Survival, Agility, Passive)
gDim = 5
local tDim = #TRAINING - 1
check("skills 'bla': rows, groups and books not kept are dimmed in place", dims() == zDim + gDim + tDim,
    dims() .. " vs " .. (zDim + gDim + tDim))
check("skills 'bla': no row hidden (35 rows laid out)", #win._skillRowZones == 35, #win._skillRowZones)
check("skills 'bla': the matched letters underlined, once per kept row", underlines() == 3, underlines())
check("skills 'bla': the count in the heading, 3 of 35", drew("3 of 35") ~= nil)
check("skills: a dimmed row is no stop", F.skillOff(win, "Carpentry") and not F.skillOff(win, "Long Blade"))
check("skills: a dimmed book row is no stop", F.trainOff(win, "Carpentry") and not F.trainOff(win, "Blacksmithing"))
-- matches are kept: the same text and data do not work them out again
local kept = win._findSkills
drawSkills(win)
check("skills: matches worked out once per text (kept across frames)", win._findSkills == kept)

typeInto(sf, "combat")
drawSkills(win)
check("skills 'combat': the combat rows not dimmed (a group name keeps its group)",
    dims() == (35 - 9) + 5 + #TRAINING, dims())
check("skills 'combat': 9 of 35", drew("9 of 35") ~= nil)

-- nothing matches
typeInto(sf, "piloting")
drawSkills(win)
check("skills 'piloting': the empty result", drew('Nothing on the Skills tab matches "piloting".') ~= nil)
check("skills 'piloting': what the field looks at", drew("The Find field looks at skills") ~= nil)
check("skills 'piloting': Clear, the default key", #buttons == 1 and buttons[1].text == "Clear" and buttons[1].variant == "primary")
check("skills 'piloting': no row and no book stops behind it", #win._skillRowZones == 0 and #win._trainingGroupZones == 0)
check("skills 'piloting': 0 of 35", drew("0 of 35") ~= nil)
F.onWindowFrame(win, 480)
local els = {}
F.stops(win, "skills", els)
check("skills 'piloting': the field and Clear are stops", #els == 2 and els[1].findField and els[2].findClear, #els)

-- Clear: the mouse on the empty result's key
local cb = win._findClearBtn.skills
check("Clear by the mouse", F.onClick(win, cb.x + 2, cb.y + 2) == true and F.text(win, "skills") == "" and sf:getText() == "")
check("Clear: the hand goes to the field", win._findLand and win._findLand.to == "field")
drawSkills(win)
check("after Clear: nothing dimmed, every row back", dims() == 0 and #win._skillRowZones == 35)
win._findLand = nil

-- X on the field clears too
typeInto(sf, "bla")
drawSkills(win); F.onWindowFrame(win, 480); drawSkills(win)
els = {}
F.stops(win, "skills", els)
els[1].onContextMenu(win, els[1])
check("X on the field clears", F.text(win, "skills") == "")

-- ===========================================================================
-- 3. THE CONTROLLER: the pad keyboard, Accept, the landing
-- ===========================================================================
do
    local w = newWin()
    drawSkills(w); F.onWindowFrame(w, 480)
    local f = w._findFields.skills
    local jd = { focus = w, id = 0 }
    JoypadState.players[1] = jd
    local shown = nil
    OnScreenKeyboard = { Show = function(pn, e, j)
        shown = { pn = pn, e = e, jd = j }
        return { textEntryBox = e }
    end }
    local els2 = {}
    F.stops(w, "skills", els2)
    els2[1].onActivate(w, els2[1])
    check("A on the field: the pad keyboard on its text box", shown and shown.e == f.input and shown.jd == jd)
    local osk = jd.focus
    check("A on the field: the keyboard holds the controller, the window after it", osk ~= w and osk.prevFocus == w)
    check("A on the field: the keyboard will say when it is accepted", type(osk.onAccept) == "function")
    typeInto(f, "bla")
    drawSkills(w)
    check("typing on the pad keyboard narrows the tab as it goes", dims() > 0)
    osk.onAccept(osk)
    check("RT: the hand will land on the first match", w._findLand and w._findLand.to == "match")
    -- the builder's stops (as ZeD_CharacterWindow builds them: dimmed rows left out)
    local stops = { { id = "skills:__disclosure", isDisclosure = true, x = 0, y = 0, w = 100, h = 37 } }
    F.stops(w, "skills", stops)
    for _, z in ipairs(w._skillRowZones) do
        if not F.skillOff(w, z.name) then stops[#stops + 1] = { id = "skill:" .. z.name, skillName = z.name, x = z.x, y = z.y, w = z.w, h = z.h } end
    end
    F.land(w, "skills", stops, function(el) return el.skillName ~= nil end)
    local landed = stops[stops._focusIdx or 0]
    local firstKept = nil
    for _, s in ipairs(stops) do if s.skillName then firstKept = s.skillName; break end end
    check("RT: the hand lands on the first matching row (in the stops' order)", landed and landed.skillName == firstKept
        and (firstKept == "Blacksmithing" or firstKept == "Long Blade" or firstKept == "Short Blade"), landed and landed.id)
    check("RT: the window rebuilds its stops at once", stops._findLand == true and w._findLand == nil)
    -- a clear lands on the field
    F.clear(w, "skills")
    local s2 = { { id = "skills:__disclosure", isDisclosure = true } }
    drawSkills(w); F.onWindowFrame(w, 480)
    F.stops(w, "skills", s2)
    s2[#s2 + 1] = { id = "skill:Aiming", skillName = "Aiming" }
    F.land(w, "skills", s2, function(el) return el.skillName ~= nil end)
    check("after a clear: the hand lands on the field", s2[s2._focusIdx or 0] and s2[s2._focusIdx].findField == true)
    -- the window closing with the keyboard on its field: the keyboard is put away
    local hidden = false
    ZeD.Keyboard = { instance = { textEntryBox = f.input }, hide = function() hidden = true end }
    F.onClose(w)
    check("closing the window puts the pad keyboard on its field away", hidden)
    ZeD.Keyboard = nil
    OnScreenKeyboard = nil
    JoypadState.players[1] = nil
end

-- QA's walk in game (Nov 11): A on the field gave no keyboard, and after RT and after X the hand
-- was on the tab strip's Loot key. A pad not bound to the player (QA drives the presses) must still
-- get the keyboard, and a landing must take the window's focus into the tab, not only the tab's stop.
do
    local w = newWin()
    drawSkills(w); F.onWindowFrame(w, 480)
    local f = w._findFields.skills
    JoypadState.players[1] = nil
    local shown = nil
    OnScreenKeyboard = { Show = function(pn, e, j)
        shown = { pn = pn, e = e, jd = j }
        return { textEntryBox = e }
    end }
    -- the window's focus ring: the tab strip (focused, on Loot) and the tab's zone
    local tabEls = {}
    F.stops(w, "skills", tabEls)
    tabEls[#tabEls + 1] = { id = "skill:Aiming", skillName = "Aiming" }
    w._focusRing = {
        { zone = "tabBar", focusable = true, elements = { { id = "tab:loot" }, { id = "tab:skills" } }, focusedElementIdx = 1 },
        { zone = "charTabContent", focusable = true, elements = tabEls, focusedElementIdx = 2 },
    }
    w._focusIdx = 1
    local function handOn()
        local z = w._focusRing[w._focusIdx]
        return z.zone .. ":" .. tostring(z.elements[z.focusedElementIdx or 1].id)
    end
    tabEls[1].onActivate(w, tabEls[1])
    check("A with no pad bound to the player: the pad keyboard still opens on the field", shown and shown.e == f.input and shown.jd == nil)
    check("A on the field: the hand is on the field under the keyboard", handOn() == "charTabContent:skills:find", handOn())
    -- (the hand put back on the strip, as QA found it after the keyboard)
    w._focusIdx = 1
    typeInto(f, "aim")
    F.accepted(w, "skills")
    local s3 = {}
    F.stops(w, "skills", s3)
    s3[#s3 + 1] = { id = "skill:Aiming", skillName = "Aiming" }
    F.land(w, "skills", s3, function(el) return el.skillName ~= nil end)
    w._focusRing[2].elements, w._focusRing[2].focusedElementIdx = s3, s3._focusIdx
    if s3._findLand then F.handIntoTab(w) end   -- (as ZeD_CharacterWindow takes a landing)
    check("RT with the window's focus on the tab strip: the hand lands on the first match in the tab",
        handOn() == "charTabContent:skill:Aiming", handOn())
    w._focusIdx = 1
    F.clear(w, "skills")
    local s4 = {}
    drawSkills(w); F.onWindowFrame(w, 480)
    F.stops(w, "skills", s4)
    s4[#s4 + 1] = { id = "skill:Aiming", skillName = "Aiming" }
    F.land(w, "skills", s4, function(el) return el.skillName ~= nil end)
    w._focusRing[2].elements, w._focusRing[2].focusedElementIdx = s4, s4._focusIdx
    if s4._findLand then F.handIntoTab(w) end
    check("X with the window's focus on the tab strip: the hand lands on the field", handOn() == "charTabContent:skills:find", handOn())
    check("with no tab zone in the ring the landing leaves the focus be", F.handIntoTab({ _focusRing = {} }) == false)
    OnScreenKeyboard = nil
end

-- ===========================================================================
-- 4. THE SKILLS TAB'S UP AND DOWN ORDER (the Transcribe key)
-- ===========================================================================
do
    -- a window's focus ring, as the FocusManager keeps it
    local function ring(els)
        return { _focusRing = { { zone = "charTabStrip", elements = {} }, { zone = "charTabContent", elements = els, focusedElementIdx = 1 } },
                 _focusIdx = 2 }
    end
    local function focused(w) local z = w._focusRing[2]; return z.elements[z.focusedElementIdx].id end
    local function press(w, dir)
        local z = w._focusRing[2]
        local el = z.elements[z.focusedElementIdx]
        if el.onDpadDir and el.onDpadDir(w, el, dir) then return true end
        return false   -- (the cone would move it: not taken here)
    end
    local function at(w, id) for j, e in ipairs(w._focusRing[2].elements) do if e.id == id then w._focusRing[2].focusedElementIdx = j end end end
    local function build(withKey, withField)
        local e = { { id = "skills:__disclosure", isDisclosure = true, x = 0, y = 0, w = 300, h = 37 } }
        if withField then e[#e + 1] = { id = "skills:find", findField = true, x = 270, y = 8, w = 200, h = 20 } end
        if withKey then e[#e + 1] = { id = "skills:stop:srj-transcribe", skillsStopId = "srj-transcribe", x = 380, y = 50, w = 90, h = 22 } end
        local y0 = withKey and 90 or 50
        e[#e + 1] = { id = "skill:Aiming", skillName = "Aiming", x = 8, y = y0, w = 220, h = 22 }
        e[#e + 1] = { id = "skill:Reloading", skillName = "Reloading", x = 8, y = y0 + 24, w = 220, h = 22 }
        e[#e + 1] = { id = "skill:Agriculture", skillName = "Agriculture", x = 240, y = y0, w = 220, h = 22 }
        e[#e + 1] = { id = "skill:Animal Care", skillName = "Animal Care", x = 240, y = y0 + 24, w = 220, h = 22,
                      onDpadDir = function(_, _, dir) return dir == "left" end }   -- (the one column's own rule)
        return e
    end
    local e = build(true, true)
    F.skillsPadOrder(e)
    local w = ring(e)
    at(w, "skill:Aiming")
    check("Up from Aiming (top of the left column) lands on the Transcribe key", press(w, "up") and focused(w) == "skills:stop:srj-transcribe", focused(w))
    check("Up from the key lands on the Find field", press(w, "up") and focused(w) == "skills:find", focused(w))
    check("Up from the field leaves the tab as before (not taken)", press(w, "up") == false)
    check("Down from the field lands on the key", press(w, "down") and focused(w) == "skills:stop:srj-transcribe", focused(w))
    check("Down from the key goes on to the rows as before (not taken)", press(w, "down") == false)
    at(w, "skills:__disclosure")
    check("Down from the disclosure lands on the key", press(w, "down") and focused(w) == "skills:stop:srj-transcribe", focused(w))
    at(w, "skill:Agriculture")
    check("Up from the top of the right column lands on the key", press(w, "up") and focused(w) == "skills:stop:srj-transcribe")
    at(w, "skill:Reloading")
    check("Up from a second row is the cone's as before", press(w, "up") == false)
    at(w, "skill:Animal Care")
    check("a row's own D-pad rule still runs first", press(w, "left") == true and focused(w) == "skill:Animal Care")
    -- the key with no Find field: Up goes to the disclosure
    local e2 = build(true, false)
    F.skillsPadOrder(e2)
    local w2 = ring(e2)
    at(w2, "skill:Aiming"); press(w2, "up")
    check("no field: Up from the key lands on the disclosure", press(w2, "up") and focused(w2) == "skills:__disclosure", focused(w2))
    -- no key: nothing changes
    local e3 = build(false, true)
    F.skillsPadOrder(e3)
    local w3 = ring(e3)
    at(w3, "skill:Aiming")
    check("no key: Up from a top row is the cone's as before", press(w3, "up") == false and e3[3].onDpadDir == nil)
    check("no key: the field and the disclosure keep the cone", e3[1].onDpadDir == nil and e3[2].onDpadDir == nil)
end

-- ===========================================================================
-- 5. THE EQUIPMENT TAB, DRAWN (the list)
-- ===========================================================================
local ew = newWin()
ew._activeTab = "equip"
VIEW = 1
drawEquip(ew)
local fig = ew._equipDefBodyFigure
check("equip, nothing typed: the Defense block draws", fig and (fig.drawn or 0) == 1)
check("equip, nothing typed: nothing dimmed", dims() == 0, dims())
local efr = F.rect(ew, "equip") or {}
local tx = ZeD.EquipDoll.toggleX(0, 480, 37)
check("equip: the field ends left of List | Doll", efr.x and efr.x + efr.w == tx - 8, efr.x and (efr.x + efr.w) .. " vs " .. tx)
check("equip: the disclosure's zone stops short of the field", ew._equipDefenseZone.w < efr.x)
F.onWindowFrame(ew, 480)
local ef = ew._findFields and ew._findFields.equip
check("equip: its own field, shown on its own tab", ef ~= nil and ef ~= (ew._findFields.skills) and ef.visible)

typeInto(ef, "hand")
drawEquip(ew)
local fig2 = ew._equipDefBodyFigure
check("equip 'hand': the Defense block hides while searching", (fig2.drawn or 0) == 1 and ew._equipDefHidden == true)
local res = ew._findEquip and ew._findEquip.res
check("equip 'hand': the gloves (slot Hands), the crowbar and the flashlight (Primary / Secondary Hand)",
    res and res.shown == 3 and res.hit.GLV == "slot" and res.hit.PRI == "slot" and res.hit.SEC == "slot", res and res.shown)
check("equip 'hand': 3 of 9 worn", drew("3 of 9") ~= nil)
-- the list folded: each group shows its worn rows; 9 rows, 6 not kept; groups with none kept: Head + face, Torso,
-- Legs + feet; and the belt's block under Held (hooks, not worn)
check("equip 'hand': the rows, groups and belt not kept dimmed in place", dims() == 6 + 3 + 1, dims())
check("equip 'hand': the slot words' letters underlined (Hands; the short words elsewhere hold none)", underlines() >= 1, underlines())
check("equip: a dimmed slot is no stop", F.equipOff(ew, "OUT") and not F.equipOff(ew, "GLV"))
check("equip: a group with nothing kept is no stop", F.equipGroupOff(ew, "head") and not F.equipGroupOff(ew, "arms"))

typeInto(ef, "foot")
drawEquip(ew)
check("equip 'foot': socks and boots by the body parts they cover", drewCount("covers ") == 2)
check("equip 'foot': the line names the parts", drew("covers Left Foot, Right Foot") ~= nil)
local res2 = ew._findEquip.res
check("equip 'foot': 2 kept, both by 'covers'", res2.shown == 2 and res2.hit.SOC == "covers" and res2.hit.BOT == "covers")

typeInto(ef, "zzz")
drawEquip(ew)
check("equip 'zzz': the empty result", drew('Nothing on the Equipment tab matches "zzz".') ~= nil and #buttons == 1)
check("equip 'zzz': no slot stops behind it", #ew._equipSlotZones == 0)

-- each tab its own text, kept across tab switches
check("each tab its own text", F.text(ew, "equip") == "zzz" and F.text(ew, "skills") == "")
ew._activeTab = "skills"
drawSkills(ew)
F.onWindowFrame(ew, 480)
check("on Skills: the Equipment field hides, its text kept", ef.visible == false and F.text(ew, "equip") == "zzz")
F.onWindowFrame(ew, 480)
ew._activeTab = "equip"
drawEquip(ew)
F.onWindowFrame(ew, 480)
check("back on Equipment: the field shows again with its text", ef.visible == true and ef:getText() == "zzz")
drawEquip(ew)
check("back on Equipment: still searching (empty result)", drew('matches "zzz"') ~= nil)

-- Clear: the Defense block comes back
ef.input:setText(""); typeInto(ef, "")
drawEquip(ew)
check("after Clear: the Defense block is back, nothing dimmed", ew._equipDefHidden == false and dims() == 0
    and (ew._equipDefBodyFigure.drawn or 0) >= 2)

-- a card over the tab (a slot opened): the heading isn't drawn, the field hides
F.onWindowFrame(ew, 480)
ew._equipSelected = "GLV"
ZeD_ItemCard = { new = function()
    return { initialise = noop, setX = noop, setY = noop, setWidth = noop, setHeight = noop, setItem = noop, setVisible = noop }
end }
panel.addChild = noop
drawEquip(ew)
F.onWindowFrame(ew, 480)
check("an item's card open: the field hides", ef.visible == false)
ew._equipSelected = nil

-- ===========================================================================
-- 6. THE DOLL VIEW
-- ===========================================================================
VIEW = 2
typeInto(ef, "hand")
drawEquip(ew); drawEquip(ew)
local dres = ew._findEquip and ew._findEquip.res
check("doll 'hand': Hands, Main hand and Off hand match", dres and dres.hit["doll:hands"] and dres.hit["doll:main"]
    and dres.hit["doll:off"] and dres.shown == 3, dres and dres.shown)
local boxes = 11 + #ZeD.EquipDoll.SMALL + 2
check("doll 'hand': every other box dimmed, the matching three keep their picture", dims() == boxes - 3, dims() .. " vs " .. (boxes - 3))
check("doll 'hand': the Defense block hidden", ew._equipDefHidden == true)
check("doll: a dimmed box is no stop", F.equipOff(ew, "doll:torso") and not F.equipOff(ew, "doll:hands"))
typeInto(ef, "upper torso")
drawEquip(ew)
check("doll 'upper torso': the boxes whose layers cover it (Torso holds the T-shirt, Outer the jacket)",
    ew._findEquip.res.hit["doll:outer"] ~= nil and ew._findEquip.res.hit["doll:torso"] ~= nil)
typeInto(ef, "")
drawEquip(ew)
check("doll, nothing typed: nothing dimmed", dims() == 0)
VIEW = 1

-- ===========================================================================
-- 6b. THE MATCHING RUNS ONCE PER TEXT, NOT PER FRAME OR DATA REFRESH
-- ===========================================================================
do
    local w = newWin()
    F.setText(w, "equip", "hand")
    F.setText(w, "skills", "bla")
    local R = F._runs
    local e0, s0, d0 = R.equip, R.skills, R.doll
    local data = ZeD.EquipmentTab.gatherData(PLAYER)
    for _ = 1, 60 do F.equip(w, data) end
    check("equip: 60 frames, one match run", R.equip == e0 + 1, R.equip - e0)
    for _ = 1, 10 do F.equip(w, ZeD.EquipmentTab.gatherData(PLAYER)) end   -- (ten data refreshes, the same outfit)
    check("equip: data refreshes with the same outfit keep the matches", R.equip == e0 + 1, R.equip - e0)
    local held = WORN[4][2]
    WORN[4][2] = SOCKS   -- (the gloves taken off, socks on the hands slot: the outfit changed)
    F.equip(w, ZeD.EquipmentTab.gatherData(PLAYER))
    check("equip: a changed outfit matches again, once", R.equip == e0 + 2, R.equip - e0)
    WORN[4][2] = held
    F.equip(w, ZeD.EquipmentTab.gatherData(PLAYER))
    F.setText(w, "equip", "foot")
    F.equip(w, ZeD.EquipmentTab.gatherData(PLAYER))
    check("equip: a new text matches again, once", R.equip == e0 + 4, R.equip - e0)
    for _ = 1, 30 do F.skills(w, skillsData(), TRAINING) end   -- (a new table every call, as each refresh)
    check("skills: refreshes with the same names keep the matches (one run)", R.skills == s0 + 1, R.skills - s0)
    F.setText(w, "skills", "combat")
    F.skills(w, skillsData(), TRAINING)
    check("skills: a new text matches again", R.skills == s0 + 2, R.skills - s0)
    local dd = ZeD.EquipDoll.gather(PLAYER, 0, true)
    for _ = 1, 20 do F.doll(w, ZeD.EquipDoll.gather(PLAYER, 0, true)) end
    check("doll: refreshes with the same outfit keep the matches (one run)", R.doll == d0 + 1, R.doll - d0)
    check("doll: the kept matches are right", w._findEquip.res.hit["doll:feet"] ~= nil, dd and "")
end

-- ===========================================================================
-- 7. THE WINDOW CLOSING
-- ===========================================================================
local fresh = newWin()
check("a new window: both texts empty (the search goes with the window)", F.text(fresh, "skills") == "" and F.text(fresh, "equip") == "")
drawSkills(fresh)
check("a new window: nothing dimmed", dims() == 0)

-- ===========================================================================
-- 8. THE NOV 12 REVIEW'S FINDINGS (each check below failed on the code before its fix)
-- ===========================================================================

-- 8a. The field lets go of the game's keyboard: after B on the pad keyboard, on Enter, hidden (another tab, an item
-- card over it) and when the window closes. A text box that keeps the keyboard takes every key while hidden or gone
-- (WASD, the hotkeys), and the game takes no interact press meanwhile: the pad's A opens no door.
do
    local w = newWin()
    drawSkills(w); F.onWindowFrame(w, 480)
    local f = w._findFields.skills
    JoypadState.players[1] = nil
    local osk = nil
    OnScreenKeyboard = { Show = function(_, e) osk = { textEntryBox = e }; return osk end }
    local els = {}
    F.stops(w, "skills", els)
    els[1].onActivate(w, els[1])
    check("A on the field: the keyboard will say when it is cancelled", osk ~= nil and type(osk.onCancel) == "function")
    f.input:focus()   -- (the keyboard's hide gives the field the caret back, then calls onCancel)
    if osk and osk.onCancel then osk.onCancel(osk) end
    check("B on the pad keyboard: the field lets go of the game's keyboard", f.input:isFocused() == false)
    OnScreenKeyboard = nil
    f.input:focus()   -- (a click in the field)
    check("Enter: the field has its submit", type(f.onSubmit) == "function")
    if f.onSubmit then f.onSubmit(f, f:getText()) end
    check("Enter: the field lets go of the game's keyboard", f.input:isFocused() == false)
    f.input:focus()
    w._activeTab = "equip"
    F.onWindowFrame(w, 480)
    check("another tab: the hidden field lets go of the game's keyboard", f.visible == false and f.input:isFocused() == false)
    f.input:focus()   -- (the pad keyboard's own hide gives a hidden field the caret back)
    F.onWindowFrame(w, 480)
    check("a hidden field given the caret back lets go of it the next frame", f.input:isFocused() == false)
    w._activeTab = "skills"
    drawSkills(w); F.onWindowFrame(w, 480); drawSkills(w)
    f.input:focus()
    F.onWindowFrame(w, 480); drawSkills(w)
    check("a field that shows keeps its caret (typing with the mouse)", f.visible == true and f.input:isFocused() == true)
    f:setVisible(false)   -- (an item card over the field: the window hides it after the window's frame)
    F.onWindowFrame(w, 480)
    check("a field an item card hid lets go of the game's keyboard the next frame", f.input:isFocused() == false)
    -- the window closing with the pad keyboard on the Skills field: it is put away (its hide gives the caret back),
    -- then both fields let go
    w._activeTab = "equip"; drawEquip(w); F.onWindowFrame(w, 480)
    local ef = w._findFields.equip
    ef.input:focus()
    local hidden = false
    ZeD.Keyboard = { instance = { textEntryBox = f.input }, hide = function() hidden = true; f.input:focus() end }
    F.onClose(w)
    check("closing the window: the pad keyboard on its field put away", hidden)
    check("closing the window: both fields let go of the game's keyboard", not f.input:isFocused() and not ef.input:isFocused())
    ZeD.Keyboard = nil
    f.input:focus()
    F.onClose(w)
    check("closing the window with no keyboard up: the field lets go too", f.input:isFocused() == false)
end

-- 8b. The help line on the field and on Clear names what A and X do (it read "A Choose  X Menu", and X clears)
do
    local w = newWin()
    drawSkills(w); F.onWindowFrame(w, 480); drawSkills(w)
    local function px(el) if type(el.promptX) == "function" then return el.promptX(w, el) end return el.promptX end
    local els = {}
    F.stops(w, "skills", els)
    check("the field's help line: A Type (as the Inventory's Filter field)", els[1].promptA == "Type", tostring(els[1].promptA))
    check("the field's help line with nothing typed: no X", px(els[1]) == false, tostring(px(els[1])))
    typeInto(w._findFields.skills, "piloting")
    drawSkills(w); F.onWindowFrame(w, 480); drawSkills(w)
    els = {}
    F.stops(w, "skills", els)
    check("the field's help line with text: X Clear", px(els[1]) == "Clear", tostring(px(els[1])))
    check("the empty result's Clear: A Clear, X not named a second time", els[2] ~= nil and els[2].promptA == "Clear"
        and els[2].promptX == false)
end

-- 8c. The Doll view while nothing matches: the doll does not draw, so its own timer does not gather the outfit again;
-- the tab does. A fedora put on while "fedora" matched nothing is found, and an outfit changed in the List view is
-- read again at once back in the Doll view.
do
    VIEW = 2
    local w = newWin()
    w._activeTab = "equip"
    local FEDORA = item("Fedora", { "Head" })
    local cap = table.remove(WORN, 1)   -- (no hat on)
    F.setText(w, "equip", "fedora")
    drawEquip(w); drawEquip(w)
    check("doll 'fedora' with no hat on: the empty result", drew('Nothing on the Equipment tab matches "fedora".') ~= nil)
    table.insert(WORN, 1, { "Base:Hat", FEDORA })   -- (a fedora put on)
    NOW = NOW + 300
    drawEquip(w)
    local r = w._findEquip and w._findEquip.res
    check("doll: a fedora put on while 'fedora' matched nothing is found", r ~= nil and r.shown == 1
        and drew('matches "fedora"') == nil, r and r.shown)
    -- a new window, the fedora on and found in the Doll view; taken off while the List view shows
    local w2 = newWin()
    w2._activeTab = "equip"
    F.setText(w2, "equip", "fedora")
    WORN[1] = { "Base:Hat", FEDORA }
    drawEquip(w2)
    local r1 = w2._findEquip and w2._findEquip.res
    VIEW = 1
    drawEquip(w2)
    WORN[1] = cap   -- (the fedora off, the cap back on)
    NOW = NOW + 300
    drawEquip(w2)
    VIEW = 2
    drawEquip(w2)
    local r2 = w2._findEquip and w2._findEquip.res
    check("doll after the outfit changed in the List view: the old outfit is not matched", r1 ~= nil and r1.shown == 1
        and r2 ~= nil and r2.shown == 0 and drew('Nothing on the Equipment tab matches "fedora".') ~= nil, r2 and r2.shown)
    VIEW = 1
end

-- 8d. A tool on the belt's hook: the List and Doll views agree (the hooks are not worn, in either view)
do
    local HAMMER = setmetatable({ _class = "HandWeapon", getDisplayName = function() return "Hammer" end,
        getCondition = function() return 8 end, getConditionMax = function() return 10 end }, NOT_CLOTHING)
    ZeD.Belt = { slots = function() return { { i = 1, key = 1, item = HAMMER, slot = { slotType = "SmallBeltLeft" } } } end,
                 provider = function() return nil end, slotName = function() return "Belt left" end,
                 cond = function() return 0.8 end }
    local w = newWin()
    w._activeTab = "equip"
    F.setText(w, "equip", "hammer")
    VIEW = 1
    drawEquip(w)
    local listShown = w._findEquip and w._findEquip.res.shown
    VIEW = 2
    drawEquip(w); drawEquip(w)
    local dollShown = w._findEquip and w._findEquip.res.shown
    check("a hammer on the belt's hook: the List and Doll views agree (a hook is not worn)", listShown == 0 and dollShown == 0,
        tostring(listShown) .. " / " .. tostring(dollShown))
    check("doll: the hooked hammer's box is dimmed and no stop", F.equipOff(w, "doll:belt1") == true)
    F.setText(w, "equip", "hand")
    drawEquip(w); drawEquip(w)
    check("doll 'hand' with a belt: the worn and held boxes match as before", w._findEquip.res.shown == 3, w._findEquip.res.shown)
    VIEW = 1
    ZeD.Belt = nil
end

-- 8e. The Equipped list's group headers and the belt's heading: the words with 6u above and below (the 15u category
-- row was half an item row, its words touching the rows around it); the belt's line one heading
do
    local cats = {}
    ZeD.Molecules.drawCategoryRow = function(_, x, y, w, text, count, expanded, opts)
        cats[#cats + 1] = { text = text, h = opts and opts.h, noArrow = opts and opts.noArrow }
        return opts and opts.h or 15
    end
    VIEW = 1
    local w = newWin()
    w._activeTab = "equip"
    drawEquip(w)
    local want = 14 + 12   -- (the F1 words, 14 tall here, with 6u above and below)
    local groups, allH, belt = 0, true, nil
    for _, c in ipairs(cats) do
        if c.noArrow then belt = c
        else groups = groups + 1; if c.h ~= want then allH = false end end
    end
    check("the Equipped group headers: their words with 6u above and below", groups == 5 and allH,
        groups .. " groups, the first " .. tostring(cats[1] and cats[1].h) .. " tall")
    check("a group's stop is its header's height", w._equipGroupZones[1] ~= nil and w._equipGroupZones[1].h == want)
    check("the belt's line is one heading, in the group headers' look and height", belt ~= nil
        and belt.text == "UI_ZeD_Equip_BeltHeadLeft" and belt.h == want)
    check("the belt's line has no second head at its right", drew("UI_ZeD_Equip_BeltHeadRight") == nil)
    ZeD.Molecules.drawCategoryRow = nil
end

-- 8f. Training materials: in the order of the names shown (the ids are not the names), and a name takes the room the
-- book squares leave it ("Blacksmith..." was cut at a third of the column with room to spare)
do
    local IDS = { Blacksmith = "Blacksmithing", Farming = "Agriculture", Electricity = "Electrical",
                  Husbandry = "Animal Care", FirstAid = "First Aid", Glassmaking = "Glassmaking" }
    SkillBook = {}
    for id in pairs(IDS) do SkillBook[id] = { perk = id } end
    PerkFactory = { getPerk = function(p) return { getName = function() return IDS[p] end } end }
    ItemType = { LITERATURE = "literature" }
    getScriptManager = function()
        return { getAllItems = function()
            local t = {}
            for id in pairs(IDS) do
                t[#t + 1] = { isItemType = function(_, k) return k == "literature" end, getSkillTrained = function() return id end,
                              getDisplayName = function() return id .. " for Beginners" end,
                              getFullName = function() return "Base.Book" .. id end, getNumberOfPages = function() return 100 end }
            end
            return list(t)
        end }
    end
    local reader = { getInventory = function() return { getItems = function() return list({}) end } end,
                     getAlreadyReadPages = function() return 0 end,
                     getAlreadyReadBook = function() return { contains = function() return false end } end }
    local rows = realTraining(reader)
    local shown = {}
    for i, r in ipairs(rows) do shown[i] = r.disp end
    check("Training materials in the order of the names they show", table.concat(shown, ", ")
        == "Agriculture, Animal Care, Blacksmithing, Electrical, First Aid, Glassmaking", table.concat(shown, ", "))
    SkillBook, PerkFactory, ItemType, getScriptManager = nil, nil, nil, nil
    local w = newWin()
    drawSkills(w)
    local cut = nil
    for _, t in ipairs(D.texts) do if string.find(t.s, "...", 1, true) then cut = t.s end end
    check("Training materials: a name with room to spare is drawn whole", cut == nil, cut)
end

-- 8g. A skill row's tag is the status square and its word (ZeD.Atoms.drawTag): measured so, the tag ends a small gap
-- short of the bar (the old box's side padding and square were still measured: a 10u hole)
do
    local tags = {}
    ZeD.Molecules.drawTag = function(_, x, y, text) tags[#tags + 1] = { x = x, text = text } end
    ZeD.Atoms.tagW = function(text, marked) return #tostring(text) * 7 + (marked and 10 or 0) end
    ZeD.SkillsTab._drawRowTags(panel, PLAYER, { name = "Axe", level = 3, boost = 3, xpProgress = 0 }, 400, 0, 20, 10, 30)
    local t = tags[1]
    local right = t and (t.x + ZeD.Atoms.tagW(t.text, true)) or 0
    check("the boost tag ends a small gap short of the bar", right == 400 - 2 - T.sp.xs, right)
    ZeD.Molecules.drawTag, ZeD.Atoms.tagW = nil, nil
end

-- 8h. An extra's block at the top of the Skills tab: its height asked once a frame (the draw takes it from the
-- measure; Skill Recovery Journal's height walks every bag for the journal)
do
    local asked = 0
    ZeD.SkillsTab.addExtras("SimHead", { headHeight = function() asked = asked + 1; return 30 end, drawHead = noop })
    drawSkills(newWin())
    check("an extra's block: its height asked once a frame", asked == 1, asked)
    for i, e in ipairs(ZeD.SkillsTab.extras) do
        if e.id == "SimHead" then table.remove(ZeD.SkillsTab.extras, i); break end
    end
end

-- 8i. No new tables or strings each frame while a search is up: the field's clear box, the typed text made ready to
-- match, the underline's cut and measures, the covers line
do
    ZeD_SearchField.render = noop
    ZeD_SearchField.drawRect, ZeD_SearchField.drawRectBorder, ZeD_SearchField.drawText = noop, noop, noop
    ZeD_SearchField.getMouseX = function() return -1 end
    ZeD_SearchField.getMouseY = function() return -1 end
    local w = newWin()
    drawSkills(w); F.onWindowFrame(w, 480)
    local f = w._findFields.skills
    typeInto(f, "bla")
    f:render()
    local r1 = f._clearR
    f:render()
    check("the field's clear box: one table, refilled each frame", r1 ~= nil and f._clearR == r1)
    typeInto(f, ""); f:render()
    check("the field's clear box: none while the field is empty", f._clearR == nil)
    typeInto(f, "bla")
    local realNorm, norms = F.norm, 0
    F.norm = function(s) norms = norms + 1; return realNorm(s) end
    drawSkills(w); drawSkills(w)
    F.norm = realNorm
    check("the typed text is made ready to match when it is typed, not each frame", norms == 0, norms)
    local realSub, subs = string.sub, 0
    string.sub = function(...) subs = subs + 1; return realSub(...) end
    drawSkills(w); drawSkills(w)
    string.sub = realSub
    check("the underline's cut and measures are kept (no string cut each frame)", subs == 0, subs)
    check("the matched rows are still underlined", underlines() == 3, underlines())
    local ew2 = newWin()
    ew2._activeTab = "equip"
    VIEW = 1
    F.setText(ew2, "equip", "foot")
    drawEquip(ew2)
    local realConcat, joins = table.concat, 0
    table.concat = function(...) joins = joins + 1; return realConcat(...) end
    drawEquip(ew2); drawEquip(ew2)
    table.concat = realConcat
    check("the covers line is kept with the matches (not joined each frame)", joins == 0, joins)
    check("the covers line is still drawn", drewCount("covers ") == 2 and drew("covers Left Foot, Right Foot") ~= nil)
end

-- 8j. The words (the real English): the Skills empty result does not promise the books (titles are not searched),
-- and the Worst zone of a part no garment protects says so ("uncovered" read wrong with a baseball cap on: a cap
-- covers no body part in the game's protection, Clothing.getCoveredParts gives none for it)
do
    local fh = io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb")
    local en = fh and fh:read("*a") or ""
    if fh then fh:close() end
    local function enText(key) return string.match(en, '"' .. key .. '": "(.-)",?\r?\n') end
    local looks = enText("UI_ZeD_Find_SkillsLooks") or ""
    local looksAt = string.match(looks, "looks at ([^;.]*)") or ""
    check("the Skills empty result does not say the field searches the books", looksAt ~= ""
        and not string.find(looksAt, "book", 1, true), looks)
    local bt = F.matchSkills(SKILLS_DATA.categories, { { label = "Carving", disp = "Carving",
        items = { { title = "Beginners Carving" } } } }, F.norm("beginners"))
    check("a book's title alone matches nothing, as the line says", bt.shown == 0 and not bt.train.Carving)
    TEXT.UI_ZeD_Equip_ZoneUncovered = enText("UI_ZeD_Equip_ZoneUncovered")
    local values = {}
    ZeD.Atoms.drawBody = function(_, s) values[#values + 1] = s end
    local w = newWin()
    w._activeTab = "equip"
    VIEW = 1
    drawEquip(w)
    ZeD.Atoms.drawBody = nil
    local worst = nil
    for _, s in ipairs(values) do if string.find(s, "Head", 1, true) then worst = s end end
    check("Worst zone, a head only a cap is on: 'Head (no protection)'", worst == "Head (no protection)", worst)
end

print(string.format("tab_search_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
