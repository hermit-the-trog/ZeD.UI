-- ZeDUI/tools/qa/woundsov_sim.lua  (Nov 7 2026, Build): ModSupport/WoundsOverhaul.lua with ZeD's Health tab and no game
-- running. The real HealthTab.lua and the support file run on Lua 5.1 stubs of the game, together with Wounds Overhaul's
-- own Lua, loaded from the SteamCMD copy (Wounds_Core, Wounds_Body, Wounds_ExamineAction, Wounds_BodyView and what they
-- require): its examination rule, its body view's examination, its examination action and its wrap of the game's
-- treatment menu are the mod's code, not copies.
--   GATED    a part the mod holds back names no wound (cut, bleeding, scratch...) in the injury list or the detail view;
--            pain and care given (a bandage) stay; the mod's "Something is wrong here." is there instead; the neck,
--            which the mod never holds back, is named
--   EXAMINE  the part's menu (right-click, and A on the controller) holds Examine and the mod's gray line, no treatment;
--            Examine queues the mod's WoundsExamineAction for the character and that part, with the familiarity and
--            workload the mod's body view works out (a first look at a cut that bleeds: 0 and 0.4); a second Examine
--            while the first is queued adds nothing (the mod's rule)
--   TREAT    once the look is done (the action's own onFinish): the wounds are named, the menu is the game's with the
--            mod's treatments (its "Press on the wound" on a bleed), opened through the mod's wrap with
--            Wounds.menuFromView set for the call only; a second look at the same findings is familiar (1.0)
--   HEALED   a part that heals loses the mod's record (the mod's own refresh), and a new wound there is held back again
--   SETTING  on the mod's "name everything" setting nothing is held back
--   OFF      with the mod off, the tab's data and the part's menu are exactly the old tab's (git show BASE)
--   OLD      the old tab (BASE) with the mod on fails GATED and EXAMINE: this sim tells the two apart
-- What it can't show: the real game's menu drawing, the action's timing in play, the mod's suture window over ZeD.
-- ZeDUI/qa/CHECK_wounds_overhaul_20261107.md is the in-game check.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/woundsov_sim.lua
-- It prints FAIL lines and a last line "woundsov_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]woundsov_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/"
local BASE = "9a879e2a"   -- the commit this work started from (its HealthTab.lua is "the old tab")
local WO = "C:/steamcmd/steamapps/workshop/content/108600/3775026731/mods/WoundsOverhaul/42/media/lua/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local SHOW = os.getenv("WOSIM_SHOW") ~= nil      -- (set it to see what the tab and the menus held)
local function show(...) if SHOW then print("   ", ...) end end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

if not readFile(WO .. "shared/Wounds_Core.lua") then
    print("woundsov_sim: Wounds Overhaul's copy is not at " .. WO .. " (SteamCMD: workshop_download_item 108600 3775026731)")
    os.exit(2)
end

-- English words: the mod's IG_UI.json and ZeD's UI.json ("key": "value" lines)
local WORDS = {}
local function loadWords(path)
    local s = readFile(path) or ""
    for k, v in s:gmatch('"([%w_]+)"%s*:%s*"(.-)"%s*,?%s*\r?\n') do WORDS[k] = v end
end
loadWords(WO .. "shared/Translate/EN/IG_UI.json")
loadWords(ROOT .. "42/media/lua/shared/Translate/EN/UI.json")
check("the mod's 'Something is wrong here.' is read", WORDS.IGUI_Wounds_Unexamined == "Something is wrong here.")
check("ZeD's Examine key is in UI.json", WORDS.UI_ZeD_Health_Examine == "Examine")

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the tab, the support file and the mod ask
-- ---------------------------------------------------------------------------
local noop = function() end
local clock = 1000000
FAULTS = {}     -- (what ZeD.logOnce was handed, every run)
local NAMES = { "Hand_L", "Hand_R", "ForeArm_L", "ForeArm_R", "UpperArm_L", "UpperArm_R", "Torso_Upper", "Torso_Lower",
                "Head", "Neck", "Groin", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }

-- a body part: st holds its state; any getter the stub does not know reads 0, any other question false
local PART = {}
PART.getType = function(self) return self.t end
PART.getIndex = function(self) return self.idx end
PART.getParentChar = function(self) return self.owner end
PART.getHealth = function(self) return self.st.health or 100 end
PART.scratched = function(self) return (self.st.scratch or 0) > 0 end
PART.getScratchTime = function(self) return self.st.scratch or 0 end
PART.isCut = function(self) return (self.st.cut or 0) > 0 end
PART.getCutTime = function(self) return self.st.cut or 0 end
PART.deepWounded = function(self) return (self.st.deep or 0) > 0 end
PART.getDeepWoundTime = function(self) return self.st.deep or 0 end
PART.bitten = function(self) return (self.st.bite or 0) > 0 end
PART.getBiteTime = function(self) return self.st.bite or 0 end
PART.bleeding = function(self) return self.st.bleeding == true end
PART.getFractureTime = function(self) return self.st.fracture or 0 end
PART.bandaged = function(self) return self.st.bandage ~= nil end
PART.getBandageLife = function(self) return self.st.bandage or 0 end
PART.getAdditionalPain = function(self) return self.st.pain or 0 end
PART.getPain = function(self) return self.st.pain or 0 end
local function newPart(i, owner)
    return setmetatable({ idx = i, t = NAMES[i + 1], st = {}, owner = owner }, { __index = function(_, k)
        if PART[k] then return PART[k] end
        if type(k) == "string" and k:sub(1, 3) == "get" then return function() return 0 end end
        return function() return false end
    end })
end
local function javaList(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             contains = function(_, x) for _, v in ipairs(t) do if v == x then return true end end return false end }
end

local player, parts
local function newPlayer()
    local p = { md = {}, perks = 0 }
    parts = {}
    for i = 0, 16 do parts[i + 1] = newPart(i, p) end
    local bd = {
        getBodyParts = function() return javaList(parts) end,
        getBodyPart = function(_, t) for _, x in ipairs(parts) do if x.t == t then return x end end end,
        getOverallBodyHealth = function() return 90 end,
    }
    p.getModData = function() return p.md end
    p.getBodyDamage = function() return bd end
    p.getPerkLevel = function() return p.perks end
    p.getPlayerNum = function() return 0 end
    p.isLocalPlayer = function() return true end
    p.isFemale = function() return false end
    p.getUsername = function() return "sim" end
    p.transmitModData = noop
    p.getInventory = function() return setmetatable({}, { __index = function() return function() return nil end end }) end
    return p
end
local function part(name) for _, x in ipairs(parts) do if x.t == name then return x end end end

-- context menus: the game hands one per player, cleared by get
local MENU
local function newMenu(x, y)
    local m = { options = {}, x = x, y = y, visible = true }
    function m:addOption(name, target, onSelect, p1, p2, p3)
        local o = { name = name, target = target, onSelect = onSelect, param1 = p1, param2 = p2, param3 = p3 }
        self.options[#self.options + 1] = o
        return o
    end
    function m:getNew() return newMenu(0, 0) end
    function m:addSubMenu() end
    function m:isEmpty() return #self.options == 0 end
    function m:setVisible(v) self.visible = v end
    function m:getIsVisible() return self.visible end
    return m
end

local VANILLA_CALLS
local function installGame(activeMods)
    clock = clock + 100000
    Events = setmetatable({}, { __index = function(t, k)
        local e = { fns = {} }
        e.Add = function(f) e.fns[#e.fns + 1] = f end
        e.Remove = noop
        rawset(t, k, e)
        return e
    end })
    getTimestampMs = function() return clock end
    getText = function(k, ...) return WORDS[k] or k end
    getTextOrNull = function(k) return WORDS[k] end
    getActivatedMods = function() return javaList(activeMods) end
    getFileWriter = function() return { write = function(_, s) WOLOG[#WOLOG + 1] = s end, close = noop } end
    isServer = function() return false end
    isClient = function() return false end
    isGamePaused = function() return false end
    getSpecificPlayer = function() return player end
    getPlayer = function() return player end
    getPlayerContextMenu = function() return MENU or {} end   -- (the game keeps one per player from the start; a dead player has none)
    getTexture = function() return nil end
    getScriptManager = function() return { FindItem = function() return nil end } end
    updateJoypadFocus = function(pad) pad.updated = true end
    JoypadState = { players = {} }
    SandboxVars = { WoundsOverhaul = {} }
    Perks = { Doctor = "Doctor" }
    BodyPartType = { FromIndex = function(i) return NAMES[i + 1] end, getDisplayName = function(t) return t end,
                     ToIndex = function(t) for i, n in ipairs(NAMES) do if n == t then return i - 1 end end end }
    for _, n in ipairs(NAMES) do BodyPartType[n] = n end
    UIFont = { Small = 1, Medium = 2 }
    Color = { new = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end }
    ISToolTip = { new = function() return { initialise = noop, setVisible = noop } end }
    ISInventoryPaneContextMenu = { transferIfNeeded = noop }

    ISBaseObject = {}
    ISBaseObject.__index = ISBaseObject
    function ISBaseObject:derive(t)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.Type = t
        return o
    end
    ISUIElement = ISBaseObject:derive("ISUIElement")
    ISPanel = ISUIElement:derive("ISPanel")
    ISPanelJoypad = ISPanel:derive("ISPanelJoypad")
    ISBodyPartPanel = ISPanelJoypad:derive("ISBodyPartPanel")
    ISBaseTimedAction = ISBaseObject:derive("ISBaseTimedAction")
    function ISBaseTimedAction.new(self, character)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.character = character
        o.stopOnWalk, o.stopOnRun, o.maxTime = true, true, -1
        return o
    end
    ISBaseTimedAction.perform = noop
    ISMedicalCheckAction = ISBaseTimedAction:derive("ISMedicalCheckAction")
    QUEUE = {}
    ISTimedActionQueue = {
        add = function(a) QUEUE[#QUEUE + 1] = a; return a end,
        getTimedActionQueue = function() return { queue = QUEUE } end,
    }
    ISContextMenu = { get = function(num, x, y) MENU = newMenu(x, y); MENU.player = num; return MENU end }

    -- the game's health panel: its treatment menu (two of vanilla's lines stand in for its handlers)
    VANILLA_CALLS = {}
    ISHealthPanel = {}
    ISHealthPanel.checkItems = noop
    ISHealthPanel.checkContainerItems = noop
    function ISHealthPanel.doBodyPartContextMenu(self, bodyPart, x, y)
        VANILLA_CALLS[#VANILLA_CALLS + 1] = { panel = self, part = bodyPart, x = x, y = y, fromView = Wounds and Wounds.menuFromView }
        local num = self.otherPlayer and self.otherPlayer:getPlayerNum() or self.character:getPlayerNum()
        local context = ISContextMenu.get(num, x + self:getAbsoluteX(), y + self:getAbsoluteY())
        context:addOption("VANILLA Bandage", bodyPart, noop)
        context:addOption("VANILLA Disinfect", bodyPart, noop)
        if JoypadState.players[num + 1] and context:getIsVisible() then
            context.origin = self
            JoypadState.players[num + 1].focus = context
        end
    end
end

-- require: the mod's own files from its copy; ZeD's HealthTab from the source being tested; the rest are stubs
local HEALTH_SOURCE
local loaded = {}
require = function(name)
    if loaded[name] then return end
    loaded[name] = true
    if name == "ZeD/HealthTab" then
        local f, err = loadstring(HEALTH_SOURCE, "=HealthTab")
        assert(f, err)
        f()
        return
    end
    local base = name:match("^(Wounds_[%w_]+)$")
    if base then
        local path = WO .. "shared/" .. base .. ".lua"
        if not readFile(path) then path = WO .. "client/" .. base .. ".lua" end
        if readFile(path) then dofile(path) end
    end
end

local function installZeD()
    ZeD = { T = { px = function(n) return n end, sp = {} } }
    ZeD.tr = function(k, a, b)
        local s = WORDS[k] or k
        if a ~= nil then s = s:gsub("%%1", tostring(a)) end
        if b ~= nil then s = s:gsub("%%2", tostring(b)) end
        return s
    end
    ZeD.logOnce = function(k, m) FAULTS[#FAULTS + 1] = tostring(k) .. ": " .. tostring(m) end
    ZeD.textCase = function(s) return s end
    ZeD_BodyFigure = {}
end

-- a fresh game: Wounds Overhaul loaded when woOn, ZeD's tab from source, the support file when withSupport
local function boot(source, woOn, withSupport)
    loaded = {}
    WOLOG = {}
    Wounds, WoundsBodyView, WoundsExamineAction = nil, nil, nil
    player = nil
    MENU = nil
    installGame(woOn and { "ZeD_UI", "WoundsOverhaul" } or { "ZeD_UI" })
    installZeD()
    player = newPlayer()
    if woOn then
        Wounds = nil
        require "Wounds_Core"
        Wounds.verbose = true          -- (its log lines land in WOLOG)
        require "Wounds_Body"
        require "Wounds_ExamineAction"
        require "Wounds_BodyView"
    end
    HEALTH_SOURCE = source
    require "ZeD/HealthTab"
    if withSupport then dofile(CLIENT .. "ZeD/ModSupport/WoundsOverhaul.lua") end
    for _, f in ipairs(Events.OnGameStart.fns) do pcall(f) end
end

-- ---------------------------------------------------------------------------
-- WHAT THE TAB SHOWS AND OPENS
-- ---------------------------------------------------------------------------
local PANEL = { getAbsoluteX = function() return 100 end, getAbsoluteY = function() return 200 end }
local function win() return { _playerObj = player, _healthContentPanel = PANEL } end

local function gather() return ZeD.HealthTab.gatherData(player) end
-- the words the tab shows for a part: its list row's tags, and its detail view (conditions and extra lines)
local function words(data, listName, figName)
    local out = {}
    for _, e in ipairs(data.entries) do
        if e.name == listName then for _, c in ipairs(e.conditions) do out[#out + 1] = c.label end end
    end
    for _, c in ipairs(data.condsByFigureName[figName] or {}) do out[#out + 1] = "detail:" .. c.label end
    for _, ln in ipairs((data.extraByFigureName or {})[figName] or {}) do out[#out + 1] = "detail:" .. ln.text end
    return table.concat(out, " | ")
end
local function has(s, w) return (s:find(w, 1, true)) ~= nil end
local function names(m)
    local out = {}
    for _, o in ipairs(m and m.options or {}) do out[#out + 1] = tostring(o.name) .. (o.notAvailable and "(gray)" or "") end
    return table.concat(out, " | ")
end
local function option(m, name)
    for _, o in ipairs(m and m.options or {}) do if o.name == name then return o end end
end
local function click(fig, viaPad)
    MENU = nil
    JoypadState.players[1] = viaPad and {} or nil
    if viaPad then ZeD.HealthTab._onPartClicked(win(), fig, nil, nil, nil)
    else ZeD.HealthTab._onPartClicked(win(), fig, PANEL, 10, 12) end
    return MENU
end

-- the wounds: a cut that bleeds on the left forearm (held back), a scratch under a fresh bandage on the right hand (held
-- back, the bandage stays), a deep wound on the neck (never held back)
local function wound()
    local fa = part("ForeArm_L"); fa.st.cut = 20; fa.st.bleeding = true; fa.st.pain = 30; fa.st.health = 70
    local h = part("Hand_R"); h.st.scratch = 10; h.st.bandage = 5
    local n = part("Neck"); n.st.deep = 12
end

-- runs the gate and examine checks on the tab as booted; returns { name = ok } so the old tab's results can be compared
local function gateChecks(tag)
    local R = {}
    local function rec(name, ok, detail) R[name] = ok and true or false; if tag then check(tag .. " " .. name, ok, detail) end end
    wound()
    local d = gather()
    local fa = words(d, "Left Forearm", "Left Forearm")
    show("forearm:", fa); show("right hand:", words(d, "Right Hand", "Right Hand")); show("neck:", words(d, "Neck", "Neck"))
    rec("held part names no cut", not has(fa, "IGUI_health_Cut") and not has(fa, "Cut"), fa)
    rec("held part names no bleeding", not has(fa, "IGUI_health_Bleeding"), fa)
    rec("held part keeps its pain", has(fa, "IGUI_health_Pain"), fa)
    rec("held part says the mod's line", has(fa, "Something is wrong here."), fa)
    local hr = words(d, "Right Hand", "Right Hand")
    rec("bandaged held part keeps the bandage", has(hr, "IGUI_health_Bandaged"), hr)
    rec("bandaged held part names no scratch", not has(hr, "IGUI_health_Scratch"), hr)
    local nk = words(d, "Neck", "Neck")
    rec("the neck is named (the mod never holds it)", has(nk, "IGUI_health_DeepWound") and not has(nk, "Something is wrong"), nk)

    local m = click("Left Forearm")
    local ex = option(m, "Examine")
    show("held menu:", names(m))
    rec("held part's menu has Examine", ex ~= nil and not ex.notAvailable, names(m))
    rec("held part's menu has the mod's gray line", option(m, "Something is wrong here.") ~= nil
        and option(m, "Something is wrong here.").notAvailable == true, names(m))
    rec("held part's menu has no treatment", not has(names(m), "VANILLA"), names(m))
    rec("the menu opens at the click", m and m.x == 110 and m.y == 212, m and (tostring(m.x) .. "," .. tostring(m.y)))
    local mp = click("Left Forearm", true)
    rec("on the controller too: Examine, and the pad lands on the menu", option(mp, "Examine") ~= nil
        and JoypadState.players[1].focus == mp and JoypadState.players[1].updated == true, names(mp))

    QUEUE = {}
    if ISTimedActionQueue then ISTimedActionQueue.getTimedActionQueue = function() return { queue = QUEUE } end end
    if ex and ex.onSelect then pcall(ex.onSelect, ex.target, ex.param1, ex.param2) end
    local a = QUEUE[1]
    show("queued:", a and a.Type, a and a.familiar, a and a.workload, a and a.maxTime, a and a.stopOnWalk)
    rec("Examine queues the mod's WoundsExamineAction", a ~= nil and getmetatable(a) == WoundsExamineAction, #QUEUE)
    rec("for the character and that part", a and a.character == player and a.bodyPart == part("ForeArm_L"))
    rec("with the mod's familiarity (a first look: 0)", a and a.familiar == 0)
    rec("with the mod's workload (bleeding 0.3 + cut 0.5, over 2: 0.4)", a and math.abs((a.workload or -1) - 0.4) < 1e-9, a and a.workload)
    rec("paying XP (the mod's rule for news)", a and a.paysXp == true)
    if ex and ex.onSelect then pcall(ex.onSelect, ex.target, ex.param1, ex.param2) end
    rec("a second Examine while one is queued adds nothing", #QUEUE == 1, #QUEUE)
    return R, a
end

-- ---------------------------------------------------------------------------
section("THE FILES")
-- ---------------------------------------------------------------------------
local nowSource = readFile(CLIENT .. "ZeD/HealthTab.lua")
local oldSource
do
    local p = io.popen('git -C "' .. (ROOT ~= "" and (ROOT:gsub("[/\\]+$", "")) or ".") .. '" show ' .. BASE .. ':42/media/lua/client/ZeD/HealthTab.lua 2>NUL')
    if p then oldSource = p:read("*a"); p:close() end
end
check("HealthTab.lua is readable", nowSource and #nowSource > 10000)
check("the old HealthTab.lua (" .. BASE .. ") is readable", oldSource and #oldSource > 10000)
do
    local s = readFile(CLIENT .. "ZeD/ModSupport/WoundsOverhaul.lua") or ""
    check("WoundsOverhaul.lua is plain ASCII", #s > 0 and not s:find("[\128-\255]"))
    -- (code only: the comments may name the mod's fields)
    local code = s:gsub("%-%-[^\n]*", "")
    local writes = 0
    for _, pat in ipairs({ "Wounds[%w_]*%.[%w_%.]+%s*=[^=]", "ISHealthPanel%.[%w_%.]+%s*=[^=]", "ISContextMenu%.[%w_%.]+%s*=[^=]",
                           "WoundsExamineAction%.[%w_%.]+%s*=[^=]" }) do
        writes = writes + select(2, code:gsub(pat, ""))
    end
    check("WoundsOverhaul.lua changes nothing of the mod's or the game's (no field written)", writes == 0, writes)
    check("it sets the mod's flag only around the game's menu", select(2, s:gsub("m%.menuFromView = true", "")) == 1
        and select(2, s:gsub("m%.menuFromView = nil", "")) == 1)
    -- (code only: comments may change their own characters, as the comment pass did)
    local function high(t)
        local code = t:gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", "")
        local _, n = code:gsub("[\128-\255]", ""); return n
    end
    check("HealthTab.lua took no new non-ASCII", nowSource and oldSource and high(nowSource) == high(oldSource))
end

-- ---------------------------------------------------------------------------
section("GATED and EXAMINE (the mod on, the new tab)")
-- ---------------------------------------------------------------------------
boot(nowSource, true, true)
check("the mod's wrap of the game's menu is on", ISHealthPanel.woundsMenuOriginal ~= nil)
check("the mod's rule holds the forearm back before the look", (function()
    wound(); return Wounds.body.needsExamFirst(part("ForeArm_L")) == true end)())
local R, action = gateChecks("new:")

-- ---------------------------------------------------------------------------
section("TREAT (the look done)")
-- ---------------------------------------------------------------------------
do
    check("the action has the mod's onFinish", action and type(action.onFinish) == "function")
    if action and action.onFinish then action.onFinish() end
    local rec = Wounds.data(player).examined and Wounds.data(player).examined["2"]
    check("the mod's record of the look is written (part 2, the left forearm)", rec ~= nil and type(rec.sig) == "string", rec and rec.sig)
    check("the mod no longer holds the forearm back", Wounds.body.needsExamFirst(part("ForeArm_L")) == false)
    clock = clock + 1000
    local d = gather()
    local fa = words(d, "Left Forearm", "Left Forearm")
    check("the cut is named now", has(fa, "IGUI_health_Cut"), fa)
    check("the bleeding is named now", has(fa, "IGUI_health_Bleeding"), fa)
    check("the mod's line is gone", not has(fa, "Something is wrong"), fa)
    VANILLA_CALLS = {}
    local m = click("Left Forearm")
    show("examined forearm:", fa); show("examined menu:", names(m)); show("mod log:", table.concat(WOLOG, " / "))
    check("the menu is the game's, through the mod's wrap", #VANILLA_CALLS == 1 and has(names(m), "VANILLA Bandage"), names(m))
    check("with the mod's treatments (Press on the wound)", option(m, WORDS.IGUI_Wounds_MenuPress or "Press on the wound") ~= nil, names(m))
    check("no Examine on an examined part", option(m, "Examine") == nil, names(m))
    check("Wounds.menuFromView set for the call", VANILLA_CALLS[1] and VANILLA_CALLS[1].fromView == true)
    check("and cleared after", Wounds.menuFromView == nil)
    check("the menu opens at the click", m and m.x == 110 and m.y == 212)
    local mp = click("Left Forearm", true)
    check("on the controller too: the treatments, the pad on the menu", has(names(mp), "VANILLA Bandage")
        and JoypadState.players[1].focus == mp, names(mp))
    -- (the right hand is still held back)
    local mh = click("Right Hand")
    check("the right hand is still held: Examine", option(mh, "Examine") ~= nil, names(mh))
end

-- ---------------------------------------------------------------------------
section("HEALED (the record goes with the wound)")
-- ---------------------------------------------------------------------------
do
    local fa = part("ForeArm_L")
    fa.st.cut, fa.st.bleeding, fa.st.pain = 0, false, 0
    clock = clock + 1000
    gather()
    local ex = Wounds.data(player).examined
    check("the healed forearm's record is dropped (the mod's refresh)", ex and ex["2"] == nil)
    fa.st.cut = 15
    clock = clock + 1000
    local d = gather()
    local w = words(d, "Left Forearm", "Left Forearm")
    check("a new cut there is held back again", not has(w, "IGUI_health_Cut") and has(w, "Something is wrong here."), w)
end

-- ---------------------------------------------------------------------------
section("A second look: familiar")
-- ---------------------------------------------------------------------------
do
    boot(nowSource, true, true)
    wound()
    local m = click("Left Forearm")
    local ex = option(m, "Examine")
    QUEUE = {}
    ex.onSelect(ex.target, ex.param1)
    QUEUE[1].onFinish()
    -- the same findings, looked at again through the mod's own rule (its panel's left click re-examines on news only)
    local view = setmetatable({ player = player, woundInfo = {}, bps = {} }, { __index = WoundsBodyView })
    WoundsBodyView.refresh(view)
    check("the mod's familiarity after ZeD's look is 1.0 (the record is the mod's)",
        WoundsBodyView.familiarity(view, "2", view.woundInfo["2"] or {}) == 1)
end

-- ---------------------------------------------------------------------------
section("SETTING (the mod's 'name everything')")
-- ---------------------------------------------------------------------------
do
    boot(nowSource, true, true)
    SandboxVars.WoundsOverhaul.RequireExamination = 3
    wound()
    local d = gather()
    local fa = words(d, "Left Forearm", "Left Forearm")
    check("nothing held: the cut is named", has(fa, "IGUI_health_Cut") and not has(fa, "Something is wrong"), fa)
    local m = click("Left Forearm")
    check("the menu is the game's with the mod's treatments", has(names(m), "VANILLA Bandage")
        and option(m, "Press on the wound") ~= nil and option(m, "Examine") == nil, names(m))
    -- the mod's rule: an axial fracture alone offers nothing
    part("Head").st.fracture = 30
    VANILLA_CALLS = {}
    local mh = click("Head")
    check("a head fracture alone opens no menu (the mod's rule)", mh == nil and #VANILLA_CALLS == 0, names(mh))
end

-- ---------------------------------------------------------------------------
section("BREAKS (the mod's view missing: the tab and menu as the mod's wrap has them)")
-- ---------------------------------------------------------------------------
do
    boot(nowSource, true, true)
    WoundsBodyView = nil
    wound()
    local d = gather()
    local fa = words(d, "Left Forearm", "Left Forearm")
    check("the words are still held back (the rule is in the mod's shared file)", not has(fa, "IGUI_health_Cut")
        and has(fa, "Something is wrong here."), fa)
    local m = click("Left Forearm")
    check("the menu is the mod's own held menu (its gray line, no error)", option(m, "Something is wrong here.") ~= nil
        and option(m, "Examine") == nil, names(m))
end

-- ---------------------------------------------------------------------------
section("OFF (the mod off: the old tab exactly)")
-- ---------------------------------------------------------------------------
local function snapshot(source, withSupport)
    boot(source, false, withSupport)
    wound()
    part("Head").st.fracture = 30
    local d = gather()
    local out = {}
    for _, e in ipairs(d.entries) do
        local tags = {}
        for _, c in ipairs(e.conditions) do tags[#tags + 1] = c.label .. "/" .. c.severity end
        out[#out + 1] = e.name .. ":" .. tostring(e.health) .. ":" .. e.worstSev .. ":" .. table.concat(tags, ",")
    end
    out[#out + 1] = "wounded " .. tostring(d.woundedCount) .. " of " .. tostring(d.injuredCount)
    for _, f in ipairs({ "Left Forearm", "Right Hand", "Neck", "Head" }) do
        out[#out + 1] = f .. " extra " .. tostring(d.extraByFigureName[f] ~= nil)
        VANILLA_CALLS = {}
        local m = click(f)
        out[#out + 1] = f .. " menu " .. names(m) .. " calls " .. #VANILLA_CALLS
    end
    return table.concat(out, "\n")
end
if oldSource and #oldSource > 10000 then
    local old = snapshot(oldSource, false)
    local new = snapshot(nowSource, true)
    check("with the mod off the tab's data and menus are the old tab's", old == new, "\nOLD:\n" .. old .. "\nNEW:\n" .. new)
    check("(and the menus are the game's)", has(new, "VANILLA Bandage"))
end

-- ---------------------------------------------------------------------------
section("OLD (the old tab with the mod on fails)")
-- ---------------------------------------------------------------------------
if oldSource and #oldSource > 10000 then
    boot(oldSource, true, false)
    local O = gateChecks(nil)
    for _, k in ipairs({ "held part names no cut", "held part names no bleeding", "held part says the mod's line",
                         "held part's menu has Examine", "Examine queues the mod's WoundsExamineAction" }) do
        check("the old tab fails '" .. k .. "'", O[k] == false)
        check("the new tab passes '" .. k .. "'", R[k] == true)
    end
end

-- ---------------------------------------------------------------------------
section("NO ERRORS")
-- ---------------------------------------------------------------------------
check("ZeD logged no fault in any run", #FAULTS == 0, table.concat(FAULTS, "; "))

print("woundsov_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
