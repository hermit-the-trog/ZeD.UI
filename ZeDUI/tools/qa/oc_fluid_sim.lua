-- ZeDUI/tools/qa/oc_fluid_sim.lua  (Nov 26 2026, Build; QA's fluid card map, 2026-11-26_map_cards_power_fluid_fire.md)
-- Loads the real ObjectCardFluid.lua and Overrides/Fluids.lua, with OC.open, ZeDOpenCardAction and OC.openNear cut
-- out of the real ObjectCards.lua, over a stub timed-action queue that works as the game's does (the head begins at
-- once and only then has its Java action; clear stops the running one and cancels the rest).
--   FL2  Empty's question names the container on the left: a Water Bottle, then (after Switch) the Rain Collector
--   FL3  Stop during the walk takes the walk and the pour out of the queue, and never calls forceStop on an action
--        that has not begun (the game's forceStop reads self.action, nil until then)
--   FL4  two Pour presses in one frame queue one pour; Pour, Switch and Empty are greyed while the chain runs and
--        come back once it is gone
--   FL7  Transfer and Info on a world container 7 and 15 tiles off walk there and open the card at the end of the
--        walk; within reach the card opens at once
--   FL5  seated, an item's Liquid > Transfer and Show info reach the game's own window; on foot the card takes them
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_fluid_sim.lua
-- It prints FAIL lines and a last line "oc_fluid_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_fluid_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("oc_fluid_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed > 0 and 1 or 0)
end
local function readFile(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- the game: the timed-action queue (as client/TimedActions/ISTimedActionQueue.lua)
-- ---------------------------------------------------------------------------
local Q = { queue = {} }
local forceStopErrors = 0
function Q:indexOf(a) for i, v in ipairs(self.queue) do if v == a then return i end end return -1 end
function Q:removeFromQueue(a) local i = self:indexOf(a); if i ~= -1 then table.remove(self.queue, i) end end
local function newAction(kind, extra)
    local a = { Type = kind, cancelled = false, stopped = false }
    -- (the game's ISBaseTimedAction:forceStop reads the Java action, nil until the action begins)
    function a:forceStop()
        if not self.action then forceStopErrors = forceStopErrors + 1; error("attempted index: forceStop of non-table") end
        self.stopped = true
    end
    function a:forceCancel() self.cancelled = true end
    function a:isStarted() return self.action ~= nil end
    function a:begin() self.action = { started = true } end
    for k, v in pairs(extra or {}) do a[k] = v end
    return a
end
ISTimedActionQueue = {
    getTimedActionQueue = function() return Q end,
    add = function(a)
        local n = #Q.queue
        Q.queue[#Q.queue + 1] = a
        if n == 0 then a:begin() end
        return Q
    end,
    clear = function()
        local head = Q.queue[1]
        if head and head.action then head.stopped = true end
        for i = 2, #Q.queue do if not Q.queue[i]:isStarted() then Q.queue[i]:forceCancel() end end
        Q.queue = {}
        return Q
    end,
    hasAction = function(a) return Q:indexOf(a) ~= -1 end,
}
local function resetQueue() Q.queue = {}; forceStopErrors = 0 end
local function count(kind)
    local n = 0
    for _, a in ipairs(Q.queue) do if a.Type == kind then n = n + 1 end end
    return n
end

-- liquids
local WATER = { getTranslatedName = function() return "Water" end, getColor = function() return nil end,
    getFluidType = function() return "Water" end, isPoisonous = function() return false end }
Fluid = { getAllFluids = function() return { size = function() return 1 end, get = function() return WATER end } end }

-- a FluidContainer: amount and capacity, water only
local function newFC(name, amt, cap)
    local fc = { name = name, amt = amt, cap = cap }
    function fc:getAmount() return self.amt end
    function fc:getCapacity() return self.cap end
    function fc:isEmpty() return self.amt <= 0 end
    function fc:isHiddenAmount() return false end
    function fc:getColor() return nil end
    function fc:getPrimaryFluid() return WATER end
    function fc:isPureFluid() return true end
    function fc:isPoisonous() return false end
    function fc:getPoisonEffect() return "None" end
    function fc:isTainted() return false end
    function fc:canPlayerEmpty() return true end
    function fc:getSpecificFluidAmount(f) return (f == WATER) and self.amt or 0 end
    function fc:getTranslatedContainerName() return self.name end
    return fc
end

-- a square and an IsoObject on it
local function newSq(x, y) return { getX = function() return x end, getY = function() return y end, getZ = function() return 0 end } end
local function isoOwner(sq) return { _iso = true, getSquare = function() return sq end } end
local function itemOwner(name) return { _item = true, getDisplayName = function() return name end, isInPlayerInventory = function() return true end,
    getTex = function() return nil end, getID = function() return 7 end } end

-- an ISFluidContainer over fc (owner: an item or an IsoObject)
local function wrapFC(fc, owner)
    local c = { fc = fc, owner = owner }
    function c:getFluidContainer() return self.fc end
    function c:isItem() return self.owner._item == true end
    function c:isIsoPanel() return self.owner._iso == true end
    function c:isResource() return false end
    function c:isValid() return true end
    function c:getOwner() return self.owner end
    function c:copy() return self end
    function c:getFluidObject() return self.fc end
    return c
end
fc_owner = {}
ISFluidContainer = { new = function(_, fc) return wrapFC(fc, fc_owner[fc] or itemOwner("?")) end }
ISFluidUtil = {
    validateContainer = function(c) return c ~= nil and c.getFluidContainer ~= nil end,
    -- (as the game's: a world container past its reach queues the walk)
    doWalkTo = function(p, c)
        local sq = c:getOwner():getSquare()
        local dx, dy = sq:getX() - p:getX(), sq:getY() - p:getY()
        if math.abs(dx) > 1.5 or math.abs(dy) > 1.5 then ISTimedActionQueue.add(newAction("ISWalkToTimedAction")) end
        return true
    end,
}
FluidContainer = { CanTransfer = function(a, b) return a ~= b and a.amt > 0 and b.amt < b.cap end, GetTransferReason = function() return nil end }
FluidUtil = { roundTransfer = function(v) return math.floor(v * 100 + 0.5) / 100 end }
ISFluidTransferAction = { new = function(_, p, a, ao, b, bo, amount)
    return newAction("ISFluidTransferAction", { character = p, amount = amount }) end }
ISInventoryPaneContextMenu = { transferIfNeeded = function() end }
ISFluidContainerMenu = { emptyFluidContainer = function() ISTimedActionQueue.add(newAction("ISFluidEmptyAction")) end }
ISWorldObjectContextMenu = { onFluidEmpty = function() ISTimedActionQueue.add(newAction("ISFluidEmptyAction")) end }
function instanceof(o, cls)
    if type(o) ~= "table" then return false end
    if cls == "InventoryItem" then return o._item == true end
    if cls == "IsoObject" then return o._iso == true end
    return false
end
function getDebug() return false end
function getTextOrNull() return nil end
function getText(k) return k end
SandboxVars = {}

-- the player
local player = { x = 100, y = 100, veh = nil, inv = {} }
function player:getX() return self.x end
function player:getY() return self.y end
function player:getZ() return 0 end
function player:getVehicle() return self.veh end
function player:getPlayerNum() return 0 end
function player:hasFullInventory() return false end
function player:getInventory()
    local items = self.inv
    return { getAllEvalRecurse = function(_, fn)
        local out = {}
        for _, it in ipairs(items) do if fn(it) then out[#out + 1] = it end end
        return { size = function() return #out end, get = function(_, i) return out[i + 1] end }
    end }
end
function getSpecificPlayer() return player end

-- ZeD: words as their key and arguments, so a check can read what a sentence was given
ZeD = { tr = function(k, ...)
    local s = k
    for _, v in ipairs({ ... }) do s = s .. "|" .. tostring(v) end
    return s
end, Safe = { on = function() return false end } }

-- ObjectCards: the call helper, the registry and the three open functions, cut from the real file
local ocSrc = readFile(Z .. "ObjectCards.lua")
local fOpen = ocSrc:match("\n(function OC%.open%(.-\nend)\n")
local fAct = ocSrc:match("\n(ZeDOpenCardAction = .-)\nfunction OC%.openNear")
local fNear = ocSrc:match("\n(function OC%.openNear%(.-\nend)\n")
local fDist = ocSrc:match("\n(function OC%.squareDist%(.-\nend)\n")
check("OC.open, ZeDOpenCardAction, OC.openNear and OC.squareDist are found in ObjectCards.lua", fOpen and fAct and fNear and fDist)
if not (fOpen and fAct and fNear and fDist) then done() end
local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
local OC = { kinds = {}, LEASH = 6, REFRESH = 15, DOT = "|", ui = {}, call = call }
function OC.register(def) OC.kinds[def.id] = def end
function OC.whereOf() return "Inventory" end
ZeD.ObjectCards = OC
ISBaseTimedAction = { derive = function(self, name) return { Type = name } end,
    new = function(cls, ch) local o = newAction(cls.Type, { character = ch }); setmetatable(o, { __index = cls }); return o end,
    perform = function() end, stop = function() end }
local walks, opened = {}, {}
luautils = { walkAdj = function(p, sq) walks[#walks + 1] = sq; ISTimedActionQueue.add(newAction("ISWalkToTimedAction")); return true end }
ZeD_WorldWindow = { openObjectCard = function(pn, entry) opened[#opened + 1] = entry; return true end }
assert(loadstring("local OC, call = ...\n" .. fDist .. "\n" .. fOpen .. "\n" .. fAct .. "\n" .. fNear, "ObjectCards cut"))(OC, call)

-- the real fluid card
function require() end
assert(loadstring(readFile(Z .. "ObjectCardFluid.lua"), "ObjectCardFluid.lua"))()
local def = OC.kinds.fluid
check("the fluid card registers", def ~= nil)
if not def then done() end

local function verb(t, id) for _, v in ipairs(t.verbs or {}) do if v.id == id then return v end end end

-- ---------------------------------------------------------------------------
-- FL2: the question names the container being emptied
-- ---------------------------------------------------------------------------
local bottleFC = newFC("Water Bottle fc", 0.5, 1.0)
local bottleItem = itemOwner("Water Bottle")
bottleItem.getFluidContainer = function() return bottleFC end
fc_owner[bottleFC] = bottleItem
player.inv = { bottleItem }
local collSq = newSq(103, 100)
local collFC = newFC("Rain Collector Barrel", 0.5, 160)
local collOwner = isoOwner(collSq)
fc_owner[collFC] = collOwner
local bottle, coll = wrapFC(bottleFC, bottleItem), wrapFC(collFC, collOwner)

resetQueue()
local t = { key = "fluid", frac = 1, from = bottle, into = coll, pinned = coll, sq = collSq }
def.refresh(t, player)
local q1 = verb(t, "empty") and verb(t, "empty").confirm or ""
check("FL2: the question names the bottle when it is on the left", q1:find("Water Bottle", 1, true) ~= nil, q1)
t.from, t.into = coll, bottle
def.refresh(t, player)
local q2 = verb(t, "empty") and verb(t, "empty").confirm or ""
check("FL2: after Switch the question names the rain collector", q2:find("Rain Collector Barrel", 1, true) ~= nil, q2)
check("FL2: the two questions differ", q1 ~= q2, q1 .. " / " .. q2)

-- ---------------------------------------------------------------------------
-- FL4: two presses in one frame, one pour; the verbs greyed while busy
-- ---------------------------------------------------------------------------
resetQueue()
collSq = newSq(105, 100)
collOwner.getSquare = function() return collSq end
t = { key = "fluid", frac = 1, from = coll, into = bottle, pinned = coll, sq = collSq }
def.refresh(t, player)
check("FL4: Pour can run before the press", verb(t, "pour") and verb(t, "pour").enabled == true)
def.pour(player, t)
def.pour(player, t)   -- (the same frame: no refresh between)
check("FL4: two presses in one frame queue one pour", count("ISFluidTransferAction") == 1, count("ISFluidTransferAction"))
check("FL4: and one walk", count("ISWalkToTimedAction") == 1, count("ISWalkToTimedAction"))
def.refresh(t, player)
check("FL4: Pour is greyed while the chain runs", verb(t, "pour") and verb(t, "pour").enabled == false and verb(t, "pour").sensible ~= false)
check("FL4: Switch is greyed while the chain runs", verb(t, "switch") and verb(t, "switch").enabled == false and verb(t, "switch").sensible ~= false)
check("FL4: Empty is greyed while the chain runs", verb(t, "empty") and verb(t, "empty").enabled == false and verb(t, "empty").sensible ~= false)
check("FL4: the greyed Pour says what it waits for", (verb(t, "pour").needs or ""):find("UI_ZeD_Fluid_NeedsIdle", 1, true) ~= nil, verb(t, "pour").needs)
check("FL4: the strip shows from the walk", t.d.pouring == true)
-- the walk ends, the pour runs: still one pour, still busy
table.remove(Q.queue, 1); Q.queue[1]:begin()
def.pour(player, t)
check("FL4: a press during the pour queues nothing", count("ISFluidTransferAction") == 1 and #Q.queue == 1, #Q.queue)
-- the pour ends: the verbs come back
Q.queue = {}
def.refresh(t, player)
check("FL4: Pour comes back once the chain is gone", verb(t, "pour").enabled == true and not t.d.busy)
check("FL4: Switch comes back", verb(t, "switch").enabled == true)

-- ---------------------------------------------------------------------------
-- FL3: Stop during the walk stops the walk and the pour
-- ---------------------------------------------------------------------------
check("FL3: the card has a Stop for its chain", type(def.stop) == "function")
local fl = readFile(Z .. "ObjectCardFluid.lua")
check("FL3: the strip's Stop no longer calls forceStop on the pour", fl:find("act:forceStop()", 1, true) == nil)
resetQueue()
t = { key = "fluid", frac = 1, from = coll, into = bottle, pinned = coll, sq = collSq }
def.refresh(t, player)
def.pour(player, t)
local walk, pour = Q.queue[1], Q.queue[2]
check("FL3: the walk runs and the pour waits", walk and walk.Type == "ISWalkToTimedAction" and pour and pour.Type == "ISFluidTransferAction" and pour.action == nil)
if def.stop then def.stop(player, t) end
check("FL3: Stop during the walk empties the queue", #Q.queue == 0, #Q.queue)
check("FL3: the walk was stopped", walk and walk.stopped == true)
check("FL3: the waiting pour was cancelled, not run", pour and pour.cancelled == true and pour.stopped == false)
check("FL3: no forceStop on an action that had not begun", forceStopErrors == 0, forceStopErrors)
def.refresh(t, player)
check("FL3: the card is idle after Stop", t.d.busy == false and t.d.pouring == false)
-- Stop with something of the player's own ahead of the card's chain: only the card's chain goes
resetQueue()
local own = newAction("ISReadABook")
ISTimedActionQueue.add(own)
def.pour(player, t)
if def.stop then def.stop(player, t) end
check("FL3: Stop leaves the player's own running action alone", #Q.queue == 1 and Q.queue[1] == own and not own.stopped, #Q.queue)
check("FL3: and takes the card's waiting chain out", count("ISFluidTransferAction") == 0 and count("ISWalkToTimedAction") == 0)
-- Stop while the pour itself runs: the game's own stop on it
resetQueue()
def.pour(player, t)
table.remove(Q.queue, 1); Q.queue[1]:begin()
local running = Q.queue[1]
if def.stop then def.stop(player, t) end
check("FL3: Stop during the pour stops it", #Q.queue == 0 and running.stopped == true and forceStopErrors == 0)

-- ---------------------------------------------------------------------------
-- FL7 and FL5: the hooks
-- ---------------------------------------------------------------------------
local vanilla = {}
ISFluidTransferUI = { OpenPanel = function() vanilla[#vanilla + 1] = "transferUI" end }
ISFluidInfoUI = { OpenPanel = function() vanilla[#vanilla + 1] = "infoUI" end }
ISFluidContainerMenu.showUI = function(p, fc, ui)
    vanilla[#vanilla + 1] = "showUI"
    -- (the game's: a one-tick action that opens the window, run here at once)
    ui.OpenPanel(p, ISFluidContainer:new(fc), nil)
end
ISWorldObjectContextMenu.onFluidTransfer = function() vanilla[#vanilla + 1] = "worldTransfer" end
ISWorldObjectContextMenu.onFluidInfo = function() vanilla[#vanilla + 1] = "worldInfo" end
assert(loadstring(readFile(Z .. "Overrides/Fluids.lua"), "Overrides/Fluids.lua"))()
local function reset() resetQueue(); walks, opened, vanilla = {}, {}, {} end

for _, far in ipairs({ 7, 15 }) do
    reset()
    collSq = newSq(100 + far, 100)
    collOwner.getSquare = function() return collSq end
    ISWorldObjectContextMenu.onFluidTransfer(0, collFC)
    check("FL7: Transfer " .. far .. " tiles off walks there", #walks == 1 and walks[1] == collSq, #walks)
    check("FL7: Transfer " .. far .. " tiles off opens the card at the end of the walk",
        #opened == 0 and Q.queue[#Q.queue] and Q.queue[#Q.queue].Type == "ZeDOpenCardAction", #opened)
    check("FL7: and does not fall to the game's window too", #vanilla == 0, table.concat(vanilla, ","))
    local last = Q.queue[#Q.queue]
    if last and last.perform then last:perform() end
    check("FL7: the walk's end opens the fluid card on the collector", #opened == 1 and opened[1].t and opened[1].t.pinned
        and opened[1].t.pinned:getFluidContainer() == collFC)
    reset()
    ISWorldObjectContextMenu.onFluidInfo(0, collFC)
    check("FL7: Info " .. far .. " tiles off walks there too", #walks == 1 and #opened == 0 and #vanilla == 0)
end
reset()
collSq = newSq(102, 100)
collOwner.getSquare = function() return collSq end
ISWorldObjectContextMenu.onFluidTransfer(0, collFC)
check("FL7: within reach the card opens at once, no walk", #walks == 0 and #opened == 1)

-- FL5: seated with a bottle
reset()
player.veh = { seat = "passenger" }
ISFluidContainerMenu.showUI(player, bottleFC, ISFluidTransferUI)
check("FL5: seated, Liquid > Transfer opens the game's window", #opened == 0 and vanilla[#vanilla] == "transferUI", table.concat(vanilla, ","))
reset()
ISFluidContainerMenu.showUI(player, bottleFC, ISFluidInfoUI)
check("FL5: seated, Show info opens the game's window", #opened == 0 and vanilla[#vanilla] == "infoUI", table.concat(vanilla, ","))
reset()
player.veh = nil
ISFluidContainerMenu.showUI(player, bottleFC, ISFluidTransferUI)
check("FL5: on foot the card takes Transfer", #opened == 1 and #vanilla == 0, table.concat(vanilla, ","))

done()
