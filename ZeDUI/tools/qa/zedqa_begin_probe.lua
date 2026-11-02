-- ZeDUI/tools/qa/zedqa_begin_probe.lua  (Nov 2 2026, QA; punch list 54, Build's probe)
-- Wraps ISBaseTimedAction.begin for the run. Before the original runs (and after its create(), which begin calls),
-- prints for each action: its Type, type() and instanceof IsoGameCharacter of self.character, type() and instanceof
-- LuaTimedActionNew of self.action, whether self.action was set before begin and after create. The original begin
-- then runs in a pcall so its error is printed too. A beard trim is then picked in Hair and beard with a razor in a
-- bag (long hair, a full beard), as zedqa_hairbeard_tools.lua does. Everything is put back.
-- grep "ZEDQA bp".
local function say(s) print("ZEDQA bp " .. tostring(s)) end
local p = getPlayer()
local HB, CW = ZeD and ZeD.HairBeard, ZeD_CharacterWindow
if not (p and HB and CW and ISBaseTimedAction) then say("ERR not loaded"); say("DONE"); return end

local function desc(v, cls)
    local t = type(v)
    local inst = false
    pcall(function() inst = instanceof(v, cls) end)
    local name = ""
    if t == "table" then name = " Type=" .. tostring(rawget(v, "Type") or (getmetatable(v) and getmetatable(v).Type))
    elseif t == "userdata" then pcall(function() name = " " .. tostring(v:getClass():getSimpleName()) end) end
    return t .. name .. " instanceof " .. cls .. "=" .. tostring(inst)
end

local origBegin = ISBaseTimedAction.begin
local count = 0
ISBaseTimedAction.begin = function(self, ...)
    count = count + 1
    local before = self.action ~= nil
    local origCreate = self.create
    local afterCreate
    -- (watch create() inside begin: wrap it on this instance only)
    self.create = function(s, ...)
        local r = origCreate(s, ...)
        afterCreate = s.action ~= nil
        say("#" .. count .. " " .. tostring(s.Type) .. " after create: character " .. desc(s.character, "IsoGameCharacter")
            .. " | action " .. desc(s.action, "LuaTimedActionNew"))
        return r
    end
    say("#" .. count .. " " .. tostring(self.Type) .. " begin: character " .. desc(self.character, "IsoGameCharacter")
        .. " | action set before " .. tostring(before))
    local ok, err = pcall(origBegin, self, ...)
    self.create = nil   -- (back to the class's create)
    say("#" .. count .. " " .. tostring(self.Type) .. " begin " .. (ok and "ok" or ("ERR " .. tostring(err))) .. " | action set after create " .. tostring(afterCreate))
    if not ok then error(err) end
end

-- the trim's own steps, one Java call at a time (its start and its update), each in a pcall with its arguments' types
local origTrimStart, origTrimUpdate = ISTrimBeard and ISTrimBeard.start, ISTrimBeard and ISTrimBeard.update
local updSaid = 0
if ISTrimBeard then
    ISTrimBeard.start = function(self)
        local anim = CharacterActionAnims and CharacterActionAnims.Shave
        say("trim start: CharacterActionAnims " .. type(CharacterActionAnims) .. " | Shave " .. desc(anim, "Enum") .. " | item " .. desc(self.item, "InventoryItem"))
        local okA, eA = pcall(function() self:setActionAnim(anim) end)
        say("trim start: setActionAnim " .. (okA and "ok" or ("ERR " .. tostring(eA))))
        local model
        local okM, eM = pcall(function() model = self.item and self.item:getStaticModel() or "DisposableRazor" end)
        say("trim start: getStaticModel " .. (okM and ("ok " .. type(model) .. " " .. tostring(model)) or ("ERR " .. tostring(eM))))
        local okH, eH = pcall(function() self:setOverrideHandModels(model, nil) end)
        say("trim start: setOverrideHandModels " .. (okH and "ok" or ("ERR " .. tostring(eH))))
    end
    ISTrimBeard.update = function(self)
        updSaid = updSaid + 1
        if updSaid > 2 then return origTrimUpdate(self) end
        local m = Metabolics and Metabolics.LightDomestic
        local okU, eU = pcall(function() self.character:setMetabolicTarget(m) end)
        say("trim update " .. updSaid .. ": Metabolics " .. type(Metabolics) .. " | LightDomestic " .. desc(m, "Metabolics") .. " | setMetabolicTarget " .. (okU and "ok" or ("ERR " .. tostring(eU))))
    end
end
-- the two Lua calls the game makes inside StartAction (BaseAction.valid -> isValid, waitToStart), each in a pcall
local origValid, origWait = ISTrimBeard and ISTrimBeard.isValid, ISTrimBeard and ISTrimBeard.waitToStart
local vSaid, wSaid = 0, 0
if ISTrimBeard then
    ISTrimBeard.isValid = function(self)
        vSaid = vSaid + 1
        local ok, r = pcall(origValid, self)
        if vSaid <= 3 then
            say("trim isValid " .. vSaid .. ": " .. (ok and ("ok " .. tostring(r)) or ("ERR " .. tostring(r))) .. " | item " .. desc(self.item, "InventoryItem")
                .. " | inventory " .. desc(self.character and self.character:getInventory(), "ItemContainer"))
            if not ok then
                local okC, eC = pcall(function() return self.character:getInventory():contains(self.item) end)
                say("  contains(item) " .. (okC and ("ok " .. tostring(eC)) or ("ERR " .. tostring(eC))))
                local okD, eD = pcall(function() return getCore():getDebug() end)
                say("  getCore():getDebug() " .. (okD and ("ok " .. tostring(eD)) or ("ERR " .. tostring(eD))))
            end
        end
        if ok then return r end
        error(r)
    end
    ISTrimBeard.waitToStart = function(self)
        wSaid = wSaid + 1
        local ok, r = pcall(origWait, self)
        if wSaid <= 3 then say("trim waitToStart " .. wSaid .. ": " .. (ok and ("ok " .. tostring(r)) or ("ERR " .. tostring(r)))) end
        if ok then return r end
        error(r)
    end
end
local hv = p:getHumanVisual()
local female = p:isFemale()
local orig = { hair = hv:getHairModel(), beard = hv:getBeardModel(), na = hv:getNonAttachedHair() }
local given = {}
local function win() return CW.getWindow() end
local function st() local w = win(); return w and w._hb end

local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end
end)
step(30, function()
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:identity" and w._activeTab ~= "identity" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    hv:setNonAttachedHair(nil)
    hv:setHairModel(female and "Long2" or "Fabian")
    if not female then hv:setBeardModel("Full") end
    p:resetModel()
    w._identityCache = nil
    local bag = p:getInventory():AddItem("Base.Bag_Schoolbag")
    given[#given + 1] = bag
    bag:getInventory():AddItem("Base.Razor")
    local s = st(); if s then s.tick = 999 end
end)
step(40, function()
    if female then say("NOTE female character: no beard; nothing picked"); return end
    local w, s = win(), st()
    HB.setPart(w, "beard")
    local pick
    for _, r in ipairs((s.byPart and s.byPart.beard and s.byPart.beard.rows) or {}) do if r.ok and r.style ~= "" then pick = r; break end end
    say("pick " .. tostring(pick and pick.key))
    if pick then say("HB.run -> " .. tostring(HB.run(w, pick.key))) end
end)
step(200, function()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local t = {}
    for _, a in ipairs(q and q.queue or {}) do t[#t + 1] = tostring(a.Type) end
    say("queue now: " .. table.concat(t, ", ") .. " | begins seen " .. count)
    pcall(ISTimedActionQueue.clear, p)
    HB.setPart(win(), "hair")
end)
step(10, function()
    ISBaseTimedAction.begin = origBegin
    if ISTrimBeard then ISTrimBeard.start, ISTrimBeard.update = origTrimStart, origTrimUpdate end
    if ISTrimBeard then ISTrimBeard.isValid, ISTrimBeard.waitToStart = origValid, origWait end
    for _, it in ipairs(given) do pcall(function() p:getInventory():Remove(it) end) end
    hv:setNonAttachedHair(orig.na)
    hv:setHairModel(orig.hair)
    if not female then hv:setBeardModel(orig.beard) end
    p:resetModel()
    say("put back")
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
