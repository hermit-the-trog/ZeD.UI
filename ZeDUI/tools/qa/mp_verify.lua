-- ZeDUI/tools/qa/mp_verify.lua  (Nov 5 2026, QA; multiplayer): Build's two fixes (2e319d78) and the cooking question,
-- on the multiplayer client (zedqa_run.ps1 -Mp). Items come from the server (admin /additem), water from a sink by the
-- game's own fill action. grep "ZEDQA mpv".
--   unequip  a hammer equipped the game's way, then ZeD's Unequip (ZeD.EquipmentTab._handleAction): the hand empties;
--            mp_hand_after.lua after a rejoin shows what the server kept (should be empty)
--   watch    the watch's Start and Speed keys (ZeD.Watch.act): the client's time multiplier and speed stay put; the
--            game's speed controls hidden
--   cook     a two-ingredient stew with the Cooking tab's Make (a pot of water, a carrot, a potato): the pots and stews
--            in the inventory after, and every ZeD_CookAdd step logged
local function say(s) print("ZEDQA mpv " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local inv = p:getInventory()
local gt = getGameTime()
local CK = ZeD and ZeD.CookingTab
local function add(ft) SendCommandToServer("/additem \"" .. p:getUsername() .. "\" \"" .. ft .. "\"") end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function idle() return not ISTimedActionQueue.isPlayerDoingAction(p) end
local function it2s(it) if not it then return "nil" end; return it:getFullType() .. "#" .. tostring(it:getID()) .. ((it:getContainer() == inv) and "@inv" or "@elsewhere") end
local function list(ft) local l = inv:getAllTypeRecurse(ft); local o = {}; for i = 0, l:size() - 1 do local it = l:get(i); local ex = it:getExtraItems(); o[#o + 1] = it2s(it) .. (ex and (" holds " .. ex:size()) or "") end; return #o .. (#o > 0 and (" [" .. table.concat(o, "; ") .. "]") or "") end

local plan, i, t0, waitUntil = {}, 1, getTimestampMs(), nil
local function add_(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function waitIdle(max) plan[#plan + 1] = { ms = 300, poll = true, max = max or 30000, fn = idle } end

-- unequip
add_(200, function() say("start; ZeD on " .. tostring(ZeD ~= nil)); add("Base.Hammer"); add("Base.WristWatch_Left_DigitalBlack") end)
add_(3000, function()
    local h = inv:getFirstTypeRecurse("Hammer")
    say("hammer " .. tostring(h ~= nil))
    if h then ISTimedActionQueue.add(ISEquipWeaponAction:new(p, h, 50, true, false)) end
    local wt = inv:getFirstTypeRecurse("WristWatch_Left_DigitalBlack")
    if wt and not wt:isEquipped() then ISTimedActionQueue.add(ISWearClothing:new(p, wt, 50)) end
end)
waitIdle()
add_(500, function()
    local h = p:getPrimaryHandItem()
    say("equipped the game's way: main hand " .. tostring(h and h:getFullType()))
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    ZeD.EquipmentTab._handleAction(CW(), "unequip", { item = h })
    say("ZeD's Unequip pressed")
end)
waitIdle()
add_(1000, function() say("after ZeD's Unequip: main hand " .. tostring(p:getPrimaryHandItem() and p:getPrimaryHandItem():getFullType())) end)
-- watch
add_(200, function()
    local sc = UIManager.getSpeedControls()
    say("before the watch keys: speed " .. tostring(sc and sc:getCurrentGameSpeed()) .. ", multiplier " .. tostring(gt:getMultiplier())
        .. ", the game's speed controls visible " .. tostring(sc and sc:isVisible()))
    say("the watch on the belt " .. tostring(ZeD.Watch and ZeD.Watch.getInstance and ZeD.Watch.getInstance() ~= nil))
    pcall(function() ZeD.Watch.act("start") end)
    pcall(function() ZeD.Watch.act("speed"); ZeD.Watch.act("speed") end)
end)
add_(3000, function()
    local sc = UIManager.getSpeedControls()
    say("after Start and Speed x2: speed " .. tostring(sc and sc:getCurrentGameSpeed()) .. ", multiplier " .. tostring(gt:getMultiplier())
        .. ", the game's speed controls visible " .. tostring(sc and sc:isVisible()))
end)
-- cook: a pot filled at the nearest sink, then a stew of two
add_(500, function() add("Base.Pot"); add("Base.Carrots"); add("Base.Potato") end)
add_(4000, function()
    local pot = inv:getFirstTypeRecurse("Pot")
    say("pot " .. tostring(pot ~= nil) .. ", carrots " .. inv:getCountTypeRecurse("Base.Carrots") .. ", potatoes " .. inv:getCountTypeRecurse("Base.Potato"))
    local cell, best, bd = getCell(), nil, 1e9
    for dx = -20, 20 do for dy = -20, 20 do
        local sq = cell:getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
        if sq then
            local objs = sq:getObjects()
            for k = 0, objs:size() - 1 do
                local o = objs:get(k)
                local ok = false
                pcall(function() ok = o:hasWater() end)
                if ok and dx * dx + dy * dy < bd then best, bd = o, dx * dx + dy * dy end
            end
        end
    end end
    say("water source " .. tostring(best and best:getObjectName()) .. (best and (" at " .. best:getX() .. "," .. best:getY()) or ""))
    if pot and best then
        luautils.walkAdj(p, best:getSquare())
        ISTimedActionQueue.add(ISTakeWaterAction:new(p, pot, best, best:isTaintedWater()))
    end
end)
waitIdle(60000)
add_(1000, function()
    local pot = inv:getFirstTypeRecurse("Pot")
    local amt = 0
    pcall(function() amt = pot:getFluidContainer():getAmount() end)
    say("pot water " .. tostring(amt))
    -- log every step of ZeD's add action
    local orig = {}
    for _, m in ipairs({ "isValidStart", "start", "perform", "complete", "stop" }) do
        orig[m] = rawget(ZeD_CookAdd, m) or ISAddItemInRecipe[m]
        ZeD_CookAdd[m] = function(self, ...)
            local r = orig[m](self, ...)
            say("ZeD_CookAdd " .. m .. " -> " .. tostring(r) .. ": dish " .. it2s(self.baseItem) .. ", chain " .. it2s(self.chain and self.chain.base) .. ", adding " .. it2s(self.usedItem))
            return r
        end
    end
    MPV_ORIG = orig
    -- the Cooking tab, Stew, the carrot and the potato, Make
    local w = CW()
    w._activeTab = "cooking"; w._drawerMode = "tab"; w._drawerOpen = true
end)
add_(1500, function()
    local w = CW(); local s = w and w._cook
    local function press(id) local z = s and s.byId and s.byId[id]; if not z then say("(no zone " .. id .. ")"); return false end; CK.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)); return true end
    MPV_PRESS = press
    press("cook:dish")
end)
add_(800, function() if not MPV_PRESS("cook:pop:dish:Stew") then say("no Stew in the Dish list") end end)
add_(800, function() MPV_PRESS("cook:ing:Base.Carrots") end)
add_(600, function() MPV_PRESS("cook:ing:Base.Potato") end)
add_(800, function() say("before Make: pots " .. list("Base.Pot") .. ", stews " .. list("Base.PotOfStew")); MPV_PRESS("cook:make") end)
add_(2000, function() end)
waitIdle(60000)
add_(2000, function()
    say("after Make: pots " .. list("Base.Pot") .. ", stews " .. list("Base.PotOfStew") .. ", carrots " .. inv:getCountTypeRecurse("Base.Carrots") .. ", potatoes " .. inv:getCountTypeRecurse("Base.Potato"))
    for m, f in pairs(MPV_ORIG or {}) do ZeD_CookAdd[m] = f end
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    local now = getTimestampMs()
    if now - t0 < st.ms then return end
    if st.poll then
        st.since = st.since or now
        local ok, done = pcall(st.fn)
        if not (ok and done) and now - st.since < st.max then return end
    end
    t0 = now; i = i + 1
    if not st.poll then local ok, e = pcall(st.fn); if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end end
end
Events.OnTick.Add(drive)
