-- ZeDUI/tools/qa/mt_actions_sim.lua  (Nov 26 2026, Build): the Vehicle tab's action faults QA proved in game
-- (ZeDUI/qa/audits/2026-11-26_map_mechanics.md; mt_tab M2 M3 M9 M11 M12 M13a), fixed in MechanicsTab.lua, checked with
-- no game running on the real MechanicsTab.lua over a stub world. The game's queue is stubbed the way
-- ISTimedActionQueue.lua keeps it (the first action begins on add; clear empties the list and leaves q.current).
--   M2   a second press while the chain is queued queues nothing (Uninstall twice: one uninstall); the tab is busy
--        while only the walk is queued; the band (with Cancel) shows from the walk on
--   M3   Install puts on the spare picked (the crate's), though a better one came into the bag after the pick
--   M9   the band's Cancel, pressed while the walk runs, empties the queue (the uninstall does not happen after);
--        a stale q.current left by the cleared queue shows no band
--   M11  paused, a right-click on a part says why nothing opens
--   M12  paused, Inflate and Smash queue nothing and say why; Smash asks no question
--   M13a Uninstall on a part whose item is already gone queues nothing and says so
--   OLD  the same cases on the tab before the fix (git show BASE): each fault reproduces, so this sim tells them apart
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mt_actions_sim.lua
-- It prints FAIL lines and a last line "mt_actions_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mt_actions_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/"
local BASE = "80af98561"   -- the commit this work started from (its MechanicsTab.lua is "the old tab")
local out = print
print = function() end   -- (the tab's load line, once per setup)

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        out("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) out("-- " .. s) end
local function noop() end
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local WORDS = {}
for k, v in (readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""):gmatch('"([%w_]+)"%s*:%s*"(.-)"%s*,?%s*\r?\n') do WORDS[k] = v end
check("ZeD's words are read", WORDS.UI_ZeD_Char_PausedLook ~= nil)
check("the part-gone words are in the English", WORDS.UI_ZeD_Veh_PartGone ~= nil)

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the tab's verbs ask
-- ---------------------------------------------------------------------------
local G = {}

local function newAction(ty, chr, fields)
    local a = { Type = ty, character = chr, started = false }
    for k, v in pairs(fields or {}) do a[k] = v end
    function a:begin() self.started = true end
    function a:isStarted() return self.started end
    function a:forceCancel() self.cancelled = true end
    function a:forceStop() self.stopped = true end
    function a:getJobDelta() return 0.25 end
    return a
end

-- ISTimedActionQueue as the game keeps it
local function newQueue()
    local q = { queue = {}, current = nil }
    function q:indexOf(a) for i, v in ipairs(self.queue) do if v == a then return i end end; return -1 end
    function q:removeFromQueue(a) local i = self:indexOf(a); if i ~= -1 then table.remove(self.queue, i) end end
    function q:addToQueue(a)
        local n = #self.queue
        self.queue[#self.queue + 1] = a
        if n == 0 then self.current = a; a:begin() end
    end
    function q:clearQueue()
        for i = 1, #self.queue do if not self.queue[i]:isStarted() then self.queue[i]:forceCancel() end end
        for i = #self.queue, 1, -1 do self.queue[i] = nil end   -- (table.wipe: q.current is left as it was)
    end
    -- the head finished: the next begins
    function q:finishHead()
        table.remove(self.queue, 1)
        self.current = self.queue[1]
        if self.current then self.current:begin() end
    end
    return q
end

local function count(ty)
    local n = 0
    for _, a in ipairs(G.q.queue) do if a.Type == ty then n = n + 1 end end
    return n
end
local function kinds()
    local o = {}
    for _, a in ipairs(G.q.queue) do o[#o + 1] = a.Type end
    return (#o > 0) and table.concat(o, ", ") or "none"
end

local function newContainer(ty)
    local c = { ty = ty }
    function c:getType() return self.ty end
    function c:getContainingItem() return nil end
    function c:getVehiclePart() return nil end
    return c
end
local function newItem(name, cond, cont)
    local it = { name = name, cond = cond, cont = cont }
    function it:getDisplayName() return self.name end
    function it:getCondition() return self.cond end
    function it:getContainer() return self.cont end
    return it
end
local function typeList(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, isEmpty = function() return #t == 0 end }
end

local function newPart(pid, v, item, opts)
    opts = opts or {}
    local p = { pid = pid, v = v, item = item }
    function p:getId() return self.pid end
    function p:getVehicle() return self.v end
    function p:getInventoryItem() return self.item end
    function p:getItemType() return opts.itype end
    function p:getArea() return "Engine" end
    function p:getWindow() return opts.window end
    function p:getTable() return nil end
    return p
end
local function newVehicle()
    local v = { parts = {} }
    function v:getId() return 7 end
    function v:getPartById(id) return self.parts[id] end
    function v:getScript() return { getMechanicType = function() return 1 end } end
    return v
end

-- the game's part handlers: the chains they queue (ISVehiclePartMenu.lua, shortened to the actions)
local function add(a) G.q:addToQueue(a) end
local function stubHandlers()
    ISVehiclePartMenu = {}
    function ISVehiclePartMenu.onUninstallPart(chr, part)
        add(newAction("ISPathFindAction", chr))
        add(newAction("ISEquipWeaponAction", chr))
        add(newAction("ISOpenVehicleDoor", chr, { vehicle = part:getVehicle() }))
        local jt = part:getInventoryItem() and "Uninstalling" or nil
        add(newAction("ISUninstallVehiclePart", chr, { part = part, vehicle = part:getVehicle(), jobType = jt }))
        add(newAction("ISCloseVehicleDoor", chr, { vehicle = part:getVehicle() }))
    end
    function ISVehiclePartMenu.onInstallPart(chr, part, item)
        G.installed = item
        add(newAction("ISPathFindAction", chr))
        add(newAction("ISInstallVehiclePart", chr, { part = part, vehicle = part:getVehicle(), item = item, jobType = "Installing" }))
    end
    function ISVehiclePartMenu.onInflateTire(chr, part)
        add(newAction("ISPathFindAction", chr))
        add(newAction("ISEquipWeaponAction", chr))
        add(newAction("ISInflateTire", chr, { part = part, vehicle = part:getVehicle(), jobType = "Inflating" }))
    end
    function ISVehiclePartMenu.onSmashWindow(chr, part)
        add(newAction("ISPathFindAction", chr))
        add(newAction("ISSmashWindow", chr, { window = part:getWindow() }))
    end
end

-- One setup: a fresh world and the tab (src: the source to load)
local function setup(src)
    G = { speed = 1, said = {}, q = newQueue(), byType = {} }
    require = function() return nil end
    Events = setmetatable({}, { __index = function(t, k) local e = { Add = noop, Remove = noop }; rawset(t, k, e); return e end })
    getTimestampMs = function() return 100000 end
    getText = function(k) return WORDS[k] or k end
    getTextOrNull = function(k) return WORDS[k] end
    getItem = function() return nil end
    getItemName = function(full) return full end
    UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return G.speed end } end }
    HaloTextHelper = { addBadText = function(chr, text) G.said[#G.said + 1] = tostring(text) end }
    ISTimedActionQueue = {
        getTimedActionQueue = function() return G.q end,
        add = function(a) G.q:addToQueue(a) end,
        clear = function() G.q:clearQueue() end,   -- (the game's: StopAllActionQueue stops the running one, then this)
    }
    VehicleUtils = { getItems = function() return G.byType, {} end }
    stubHandlers()
    ZeD = {
        tr = function(k, ...)
            local t, args = WORDS[k] or k, { ... }
            return (string.gsub(t, "%%(%d)", function(n) local v = args[tonumber(n)]; return v ~= nil and tostring(v) or ("%" .. n) end))
        end,
        trBare = function(k) return WORDS[k] or k end,
        textCase = function(s) return s end,
        Atoms = { drawProgressBand = function(panel, x, y, w, kind, label, pct, a8, rect)
            G.bandLabel = label
            if rect then rect.x, rect.y, rect.w, rect.h = x + w - 20, y, 16, 16 end
            return 24
        end },
    }
    G.inv = newContainer("none")
    G.chr = { }
    function G.chr:getPlayerNum() return 0 end
    function G.chr:getInventory() return G.inv end
    function G.chr:getVehicle() return nil end
    G.v = newVehicle()
    local f, err = loadstring(src, "@MechanicsTab.lua")
    check("MechanicsTab.lua compiles", f ~= nil, err)
    local okL, errL = pcall(f)
    check("MechanicsTab.lua loads on the stubs", okL, errL)
    G.MT = ZeD.MechanicsTab
    G.s = { vehicles = {}, idx = 1, zones = {}, byId = {}, pick = 1, fixPick = 1 }
    return G
end

local function band()
    G.s.zones, G.s.byId = {}, {}
    G.bandLabel = nil
    local h = G.MT._h.progressBand({}, {}, G.s, 0, 0, 500, G.v, G.chr)
    return h, G.s.byId["mech:cancel"]
end

-- ---------------------------------------------------------------------------
-- The cases, each returning what it saw (run on the fixed tab and on the old one)
-- ---------------------------------------------------------------------------
local C = {}

function C.m2()
    local part = newPart("Battery", G.v, newItem("Battery", 80))
    G.v.parts.Battery = part
    G.MT._test.runVerb(G.s, "uninstall", part, G.chr)
    local h, cancel = band()   -- (the head is the walk)
    local busy = G.MT._test.chainBusy and G.MT._test.chainBusy(G.s, G.chr)
    G.MT._test.runVerb(G.s, "uninstall", part, G.chr)
    return { n = count("ISUninstallVehiclePart"), kinds = kinds(), bandOnWalk = h > 0 and cancel ~= nil, busy = busy, label = G.bandLabel }
end

function C.m3()
    local crate = newContainer("crate")
    local bag71 = newItem("Tire", 71, G.inv)
    local crate70 = newItem("Tire", 70, crate)
    local part = newPart("TireFrontLeft", G.v, nil, { itype = typeList({ "Base.OldTire" }) })
    G.v.parts.TireFrontLeft = part
    G.byType = { ["Base.OldTire"] = { bag71, crate70 } }
    -- the crate's spare picked: row 2, as the click on its row records it
    G.s.pick, G.s.pickItem = 2, crate70
    -- a better spare comes into his bag after the pick (the tab reads the items again)
    local bag90 = newItem("Tire", 90, G.inv)
    G.byType = { ["Base.OldTire"] = { bag90, bag71, crate70 } }
    G.s.items = nil
    G.MT._test.runVerb(G.s, "install", part, G.chr)
    local who = (G.installed == crate70 and "crate70") or (G.installed == bag71 and "bag71") or (G.installed == bag90 and "bag90") or "none"
    return { who = who }
end

function C.m9()
    local part = newPart("Battery", G.v, newItem("Battery", 80))
    G.v.parts.Battery = part
    G.MT._test.runVerb(G.s, "uninstall", part, G.chr)
    G.q:finishHead()   -- the walk done, the equip runs: still no job name at the head
    local _, cancel = band()
    if cancel then cancel.fn() end
    local r = { cancelThere = cancel ~= nil, left = #G.q.queue, kinds = kinds() }
    local h2 = band()
    r.bandAfter = h2 > 0
    return r
end

function C.m12()
    local tire = newPart("TireFrontLeft", G.v, newItem("Tire", 80))
    local glass = newPart("WindowFrontLeft", G.v, newItem("Window", 80), { window = {} })
    G.v.parts.TireFrontLeft, G.v.parts.WindowFrontLeft = tire, glass
    G.speed = 0
    G.MT._test.runVerb(G.s, "inflate", tire, G.chr)
    local k1, n1 = kinds(), #G.q.queue
    G.MT._test.runVerb(G.s, "smash", glass, G.chr)
    local k2, n2 = kinds(), #G.q.queue - n1
    local asked = nil
    if G.MT._test.pressVerb then
        local cm = { part = glass, busy = false, needs = { smash = { ok = true } } }
        G.MT._test.pressVerb({}, G.s, cm, "smash", G.chr)
        asked = G.s.confirm
    end
    return { n1 = n1, k1 = k1, n2 = n2, k2 = k2, said = #G.said, asked = asked }
end

function C.m11()
    G.speed = 0
    G.ctxShown = false
    local ui = { getAbsoluteX = function() return 0 end, getAbsoluteY = function() return 0 end }
    -- the game's own: returns at speed 0 and says nothing (ISVehicleMechanics:209)
    ui.doPartContextMenu = function(self) if G.speed == 0 then return end; G.ctxShown = true end
    getPlayerMechanicsUI = function() return ui end
    getMouseX = function() return 0 end
    getMouseY = function() return 0 end
    local part = newPart("TireFrontLeft", G.v, newItem("Tire", 80))
    G.MT._test.partContextMenu(part, G.chr)
    return { shown = G.ctxShown, said = #G.said }
end

function C.m13()
    local part = newPart("TireRearLeft", G.v, nil)   -- (taken off in the same frame)
    G.v.parts.TireRearLeft = part
    G.MT._test.runVerb(G.s, "uninstall", part, G.chr)
    return { n = count("ISUninstallVehiclePart"), kinds = kinds(), said = G.said[1] }
end

-- ===========================================================================
section("FIXED (the tab as it is)")
local src = readFile(CLIENT .. "ZeD/MechanicsTab.lua")
setup(src)
local r = C.m2()
check("M2: Uninstall pressed twice queues one uninstall", r.n == 1, r.kinds)
check("M2: busy while only the walk is queued", r.busy == true)
check("M2: the band shows from the walk on, with Cancel", r.bandOnWalk == true)
check("M2: the band names the verb and the part while the walk runs", type(r.label) == "string" and r.label:find("Battery", 1, true) ~= nil, r.label)

setup(src)
r = C.m3()
check("M3: Install puts on the spare picked (the crate's 70), not the row it was on", r.who == "crate70", r.who)
setup(src)
local s3 = G.s
local a, b = newItem("A", 50, G.inv), newItem("B", 90, G.inv)
local pk = G.MT._test.pickedInstall(s3, { { item = a, cond = 50 }, { item = b, cond = 90 }, { none = true } })
check("M3: with none picked the first row is taken and kept", pk and pk.item == a and s3.pickItem == a and s3.pick == 1)
pk = G.MT._test.pickedInstall(s3, { { item = b, cond = 90 }, { item = a, cond = 50 } })
check("M3: the kept pick follows its item to another row", pk and pk.item == a and s3.pick == 2)

setup(src)
r = C.m9()
check("M9: Cancel is on the band while the walk and the equip run", r.cancelThere == true)
check("M9: Cancel empties the queue (no uninstall after it)", r.left == 0, r.kinds)
check("M9: no band after Cancel (the cleared queue's stale current is not read as running)", r.bandAfter == false)

setup(src)
r = C.m12()
check("M12: paused, Inflate queues nothing", r.n1 == 0, r.k1)
check("M12: paused, Smash queues nothing", r.n2 == 0, r.k2)
check("M12: paused, the player is told", r.said >= 2, r.said)
check("M12: paused, Smash asks no question", r.asked == nil, r.asked)
G.speed = 1
G.said = {}
G.MT._test.runVerb(G.s, "inflate", G.v.parts.TireFrontLeft, G.chr)
check("M12: playing, Inflate queues its chain and says nothing", count("ISInflateTire") == 1 and #G.said == 0, kinds())

setup(src)
r = C.m11()
check("M11: paused, a right-click on a part says why nothing opens", r.said == 1 and r.shown == false, r.said)

setup(src)
r = C.m13()
check("M13a: Uninstall on a part already gone queues nothing", r.n == 0, r.kinds)
check("M13a: and says so, naming the part", r.said ~= nil and r.said:find("%1", 1, true) == nil, r.said)

-- ===========================================================================
section("OLD (the tab before the fix: each fault reproduces)")
local pipe = io.popen('git -C "' .. (ROOT ~= "" and ROOT or ".") .. '" show ' .. BASE .. ':42/media/lua/client/ZeD/MechanicsTab.lua 2>NUL')
local oldSrc = pipe and pipe:read("*a") or ""
if pipe then pipe:close() end
if oldSrc == "" then
    out("   (OLD skipped: git show " .. BASE .. " gave nothing)")
else
    setup(oldSrc)
    r = C.m2()
    check("OLD M2: a second press queued a second uninstall", r.n == 2, r.kinds)
    check("OLD M2: no band during the walk", r.bandOnWalk == false)
    setup(oldSrc)
    r = C.m3()
    check("OLD M3: Install put on the bag's spare on the picked row", r.who == "bag71", r.who)
    setup(oldSrc)
    r = C.m9()
    check("OLD M9: no Cancel while the walk runs: the uninstall stays queued", r.cancelThere == false and r.left > 0, r.kinds)
    setup(oldSrc)
    r = C.m12()
    check("OLD M12: paused, Inflate and Smash queued, nothing said", r.n1 > 0 and r.n2 > 0 and r.said == 0, r.k1 .. " / " .. r.k2)
    setup(oldSrc)
    r = C.m11()
    check("OLD M11: paused, the right-click said nothing", r.said == 0 and r.shown == false)
    setup(oldSrc)
    r = C.m13()
    check("OLD M13a: Uninstall on a part already gone queued the uninstall, nothing said", r.n == 1 and r.said == nil, r.kinds)
end

print = out
out(string.format("mt_actions_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
