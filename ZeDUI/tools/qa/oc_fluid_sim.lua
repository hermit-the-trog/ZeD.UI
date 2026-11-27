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
--   FL6  a well (the game's HiddenAmount) shows Unknown, no litres, no share and no lit segments; Max Pour hides
--        too when the hidden side sets it; a plain barrel still shows its amount
--   PW9 / FI9  Info on a generator, a campfire or a barbecue 7 and 15 tiles off (Overrides/InfoCards.lua) walks
--        there and opens the card at the walk's end; in reach at once; with no path the game's own Info runs
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
-- (QA TG7, Nov 26 2026) the pour's end asks the frame to go back to the card this one came from
check("TG7: the end of the pour asks for the way back (t._returnNow)", t._returnNow == true)
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
check("TG7: a stopped pour does not send the player back", t._returnNow ~= true)
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

-- ---------------------------------------------------------------------------
-- FL6: a well hides its amount; the card draws no number for it and no lit segments
-- ---------------------------------------------------------------------------
-- a card that keeps what it draws: every string, and every segment strip with how many segments it lit
local drawn, segs = {}, {}
local function noteText(s) drawn[#drawn + 1] = tostring(s) end
local COL = { r = 1, g = 1, b = 1, a = 1 }
ZeD.T = setmetatable({ px = function(n) return n end, selectionA = 0.2, fillBarH = 6, buttonH = 20 },
    { __index = function() return COL end })
ZeD.TM = { MeasureStringX = function(_, _, s) return #tostring(s) end, getFontHeight = function() return 10 end }
ZeD.Atoms = {
    drawSegFill = function(_, _, _, _, _, _, lit) segs[#segs + 1] = lit; return false end,
    fillSegsLit = function(f) return math.floor((f or 0) * 10 + 0.5) end,
    fillBarCompactH = function() return 4 end,
    drawTextRight = function(_, s) noteText(s) end,
    textCase = function(s) return s end,
    frame = function() end, drawStatusDot = function() end, drawSmoothBar = function() end,
}
ZeD.Help = { set = function() end }
ZeD.CraftingCore = { truncText = function(s) return s end }
ZeD.Molecules = { drawEmptyLine = function(_, _, _, _, s) noteText(s) end }
ZeD.Focus = { mark = function() end }
OC.ui.fill = function() end
OC.ui.section = function(_, _, _, _, a, b) noteText(a); noteText(b); return 10 end
OC.ui.tag = function(_, _, _, s) noteText(s) end
OC.ui.tagW = function(s) return #tostring(s) end
OC.ui.button = function(_, _, _, s) noteText(s) end
OC.ui.buttonW = function(s) return #tostring(s) end
OC.ui.big = function(_, s) noteText(s) end
local CARD = {
    drawText = function(_, s) noteText(s) end,
    drawRect = function() end, drawRectBorder = function() end, drawTextureScaledAspect = function() end,
    zone = function() end, focusOf = function() return nil end,
}
local BLUE = { getRedFloat = function() return 0.2 end, getGreenFloat = function() return 0.4 end, getBlueFloat = function() return 0.9 end }
local function hiddenFC(name, amt, cap)
    local fc = newFC(name, amt, cap)
    function fc:isHiddenAmount() return true end
    function fc:getColor() return BLUE end
    return fc
end
local function drawCard(t)
    drawn, segs = {}, {}
    def.refresh(t, player)
    def.body(CARD, 0, 0, 480, t, player)
    return table.concat(drawn, " / ")
end
local function litSum() local n = 0; for _, v in ipairs(segs) do n = n + (v or 0) end; return n end

do
    resetQueue()
    -- the player carries an empty bottle, so every segment the card lights would be the well's
    local emptyFC = newFC("Empty Bottle fc", 0, 1.0)
    local emptyItem = itemOwner("Empty Bottle")
    emptyItem.getFluidContainer = function() return emptyFC end
    fc_owner[emptyFC] = emptyItem
    player.inv = { emptyItem }
    local wellSq = newSq(102, 100)
    local wellFC = hiddenFC("Well", 6074, 10000)
    local wellOwner = isoOwner(wellSq)
    fc_owner[wellFC] = wellOwner
    local well, emptyB = wrapFC(wellFC, wellOwner), wrapFC(emptyFC, emptyItem)
    local tw = { key = "fluid", frac = 1, from = well, into = emptyB, pinned = well, sq = wellSq }
    local okB, s = pcall(drawCard, tw)
    check("FL6: the card draws over a well", okB, s)
    s = okB and s or ""
    check("FL6: no 6074 anywhere on the card", s:find("6074", 1, true) == nil, s)
    check("FL6: the game's Unknown in its place", s:find("Unknown", 1, true) ~= nil, s)
    check("FL6: no share either (the Liquids row's 100%)", s:find("100%", 1, true) == nil, s)
    check("FL6: no lit segments (the well's row and its Liquids bar)", #segs > 0 and litSum() == 0, table.concat(segs, ","))
    local q = verb(tw, "empty") and verb(tw, "empty").confirm or ""
    check("FL6: Empty's question names no amount", q:find("6074", 1, true) == nil, q)
    -- the bottle sets the most a pour takes: that number is the bottle's, so it shows
    check("FL6: the pour's Max Pour is the bottle's 1 L (it gives nothing away)", s:find("Max Pour 1.00 L", 1, true) ~= nil and not tw.d.maxHidden, s)

    -- a nearly dry hidden source sets Max Pour itself: then the amount reads Unknown too
    local lowFC = hiddenFC("Well", 0.3, 10000)
    fc_owner[lowFC] = wellOwner
    local low = wrapFC(lowFC, wellOwner)
    local tl = { key = "fluid", frac = 1, from = low, into = emptyB, pinned = low, sq = wellSq }
    local okL, s2 = pcall(drawCard, tl)
    s2 = okL and s2 or ""
    check("FL6: a hidden side that sets Max Pour hides it", okL and tl.d.maxHidden == true and s2:find("0.30", 1, true) == nil, s2)

    -- a plain barrel still shows its amount and lights its segments
    local barFC = newFC("Barrel", 80, 160)
    function barFC:getColor() return BLUE end
    fc_owner[barFC] = wellOwner
    local bar = wrapFC(barFC, wellOwner)
    local tb = { key = "fluid", frac = 1, from = bar, into = emptyB, pinned = bar, sq = wellSq }
    local okP, s3 = pcall(drawCard, tb)
    s3 = okP and s3 or ""
    check("FL6: a barrel that does not hide shows 80.0 L", s3:find("80.0 L", 1, true) ~= nil, s3)
    check("FL6: and lights its segments", litSum() > 0, table.concat(segs, ","))
    player.inv = { bottleItem }
end

-- ---------------------------------------------------------------------------
-- PW9 / FI9: Info on a generator or a fire past the card's reach walks there and opens the card on arrival
-- (Overrides/InfoCards.lua through OC.openNear); in reach it opens at once; no path hands it to the game
-- ---------------------------------------------------------------------------
do
    local gameInfo = {}
    ISWorldObjectContextMenu.onInfoGenerator = function() gameInfo[#gameInfo + 1] = "generator" end
    ISCampingMenu = { onDisplayInfo = function() gameInfo[#gameInfo + 1] = "campfire" end }
    ISBBQMenu = { onDisplayInfo = function() gameInfo[#gameInfo + 1] = "bbq" end }
    local function kind(id) OC.kinds[id] = { id = id, resolve = function(_, obj) return { key = id, obj = obj } end } end
    kind("generator"); kind("fire")
    assert(loadstring(readFile(Z .. "Overrides/InfoCards.lua"), "Overrides/InfoCards.lua"))()
    local objSq
    local thing = { getSquare = function() return objSq end }
    -- the campfire's Lua object: its square only through its tile
    local luaFire = { getIsoObject = function() return thing end }
    local cases = {
        { "generator", function() ISWorldObjectContextMenu.onInfoGenerator({}, thing, 0) end },
        { "campfire", function() ISCampingMenu.onDisplayInfo({}, player, luaFire) end },
        { "barbecue", function() ISBBQMenu.onDisplayInfo({}, 0, thing) end },
    }
    for _, c in ipairs(cases) do
        for _, far in ipairs({ 7, 15 }) do
            reset(); gameInfo = {}
            objSq = newSq(100 + far, 100)
            c[2]()
            check("PW9/FI9: Info on the " .. c[1] .. " " .. far .. " tiles off walks there", #walks == 1 and walks[1] == objSq, #walks)
            local last = Q.queue[#Q.queue]
            check("PW9/FI9: ... the card waits for the walk's end", #opened == 0 and last and last.Type == "ZeDOpenCardAction", #opened)
            if last and last.perform then last:perform() end
            check("PW9/FI9: ... and opens there", #opened == 1 and #gameInfo == 0, #opened)
        end
        reset(); gameInfo = {}
        objSq = newSq(102, 100)
        c[2]()
        check("PW9/FI9: Info on the " .. c[1] .. " in reach opens at once", #walks == 0 and #opened == 1 and #gameInfo == 0)
    end
    -- no path: never nothing; the game's own Info runs
    local walkAdj = luautils.walkAdj
    luautils.walkAdj = function() return false end
    reset(); gameInfo = {}
    objSq = newSq(115, 100)
    ISWorldObjectContextMenu.onInfoGenerator({}, thing, 0)
    check("PW9: no path to the generator: the game's Info runs", #opened == 0 and gameInfo[1] == "generator", table.concat(gameInfo, ","))
    luautils.walkAdj = walkAdj
end

done()
