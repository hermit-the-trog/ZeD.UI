-- ZeDUI/tools/qa/zedqa_container_v2.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: container buttons v2 (icons with hover hints at
-- the bottom, the container's own actions in its heading). Steps, one per
-- go-file run (ZEDQA_V2_STEP), so the real mouse can hover between them:
--   "bed"    beside the pickup's truck bed (nails seeded), both windows on it;
--            logs every button in screen pixels ("ZEDQA v2 btn key x y w h");
--   "pad"    the controller on Take all (shot), then released;
--   "fire"   a campfire beside you, out: its heading (shot), logs buttons;
--   "lit"    the campfire lit (fuel added): Add fuel and Put out (shot);
--   "large"  the large text size: the heading's ribbon (shot), back to small;
--   "fuel"   Add fuel pressed: the fire card on its fuel list (shot);
--   "end"    the campfire and the nails taken away, windows closed.
-- grep "ZEDQA v2"; captures Screenshots/zqa_v2_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local CT = ZeD.ContainerControls
local function say(s) print("ZEDQA v2 " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_v2_" .. n .. ".png") end) end
local function ww() return ZeD_WorldWindow.getWindow() end
local function wc() return ww()._mainContent end
local function camp() return getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), 0) end
local function select(pred)
    local w = ww()
    for i, c in ipairs(w._containers or {}) do
        if c.inventory and pred(c.inventory) then w._activeContainer = i; w._viewedContainer = nil; w._mainVisible = false; return true end
    end
    return false
end
local function logButtons(content, tag)
    local cc = content._cc
    for i, h in ipairs(cc and cc.hits or {}) do
        say(string.format("btn %s %s %d %d %d %d %s", tag, h.key, content:getAbsoluteX() + h.x, content:getAbsoluteY() + h.y, h.w, h.h, tostring(h.label)))
    end
end
local function later(n, fn)
    local t = 0
    local function f() t = t + 1; if t >= n then Events.OnTick.Remove(f); local ok, e = pcall(fn); if not ok then say("ERR " .. tostring(e)) end end end
    Events.OnTick.Add(f)
end
ZEDQA_V2 = ZEDQA_V2 or { given = {} }
local step = ZEDQA_V2_STEP or "bed"

if step == "bed" then
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if v:getScriptName() == "Base.PickUpTruck" then local d = v:DistTo(p); if not bd or d < bd then best, bd = v, d end end
    end
    local part = best and (best:getPartById("TruckBed") or best:getPartById("TruckBedOpen"))
    local c = part and best:getAreaCenter(part:getArea())
    if c then p:teleportTo(c:getX(), c:getY(), 0) end
    ZEDQA_V2.bed = part and part:getItemContainer()
    later(30, function()
        for _ = 1, 3 do ZEDQA_V2.given[#ZEDQA_V2.given + 1] = ZEDQA_V2.bed:AddItem("Base.Nails") end
        for _ = 1, 2 do ZEDQA_V2.given[#ZEDQA_V2.given + 1] = p:getInventory():AddItem("Base.Nails") end
        if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
        later(30, function()
            say("bed selected " .. tostring(select(function(inv) return inv == ZEDQA_V2.bed end)))
            later(30, function()
                logButtons(wc(), "world")
                logButtons(ZeD_CharacterWindow.getWindow()._mainContent, "char")
                shot("01_bed")
            end)
        end)
    end)
elseif step == "pad" then
    local F, D = ZeD.Input.Focus, ZeD.Input.Detector
    D.setLockedMode("gamepad")
    F.claimFocus(ww())
    for zi, z in ipairs(ww()._focusRing) do
        if z.zone == "worldCtl" then
            ww()._focusIdx = zi
            for ei, e in ipairs(z.elements) do if e.ccKey == "take" then z.focusedElementIdx = ei end end
        end
    end
    later(20, function()
        local el = F.getFocusedElement(ww())
        say("focused " .. tostring(el and el.id) .. " prompt " .. tostring(el and el.promptA))
        shot("03_pad_take_all")
        later(5, function() D.setLockedMode(nil); F.releaseFocus() end)
    end)
elseif step == "fire" then
    local lo = camp() and SCampfireSystem.instance:getLuaObjectOnSquare(camp())
    if not lo then SCampfireSystem.instance:addCampfire(camp()) end
    later(60, function()
        say("campfire selected " .. tostring(select(function(inv) return inv:getType() == "campfire" end)))
        later(30, function()
            local cc = wc()._cc
            local t = {}
            for _, s in ipairs(cc and cc.objs or {}) do t[#t + 1] = s.label .. (s.icon and ("[" .. s.icon .. "]") or "") end
            say("heading: " .. table.concat(t, ", ") .. " | down " .. tostring(cc and cc.objsDown))
            logButtons(wc(), "fire")
            shot("05_campfire_out")
        end)
    end)
elseif step == "lit" then
    local lo = SCampfireSystem.instance:getLuaObjectOnSquare(camp())
    local ok, e = pcall(function() lo.fuelAmt = 120; lo:lightFire(); lo:saveData() end)
    say("lit " .. tostring(ok) .. " " .. tostring(e))
    later(90, function()
        local cc = wc()._cc
        local t = {}
        for _, s in ipairs(cc and cc.objs or {}) do t[#t + 1] = s.label .. (s.icon and ("[" .. s.icon .. "]") or "") end
        say("heading, lit: " .. table.concat(t, ", "))
        logButtons(wc(), "lit")
        shot("07_campfire_lit")
    end)
elseif step == "large" then
    local base, accent = ZeD.currentBase, ZeD.currentAccent
    ZeD.applyTheme(base, accent, "large")
    later(40, function()
        local cc = wc()._cc
        local S = cc and cc.strips and cc.strips.head and cc.strips.head.scroll
        say("large: heading scrolls " .. tostring(S ~= nil) .. " down " .. tostring(cc and cc.objsDown))
        shot("08_large_text")
        later(5, function() ZeD.applyTheme(base, accent, "small") end)
    end)
elseif step == "fuel" then
    for i, h in ipairs(wc()._cc.hits or {}) do
        if h.key == "obj:ISLootWindowObjectControlHandler_AddFuelOption" then CT.press(wc(), i) end
    end
    later(30, function()
        say("object card " .. tostring(ww()._drawerObject ~= nil))
        shot("09_add_fuel")
        later(5, function() ZeD_WorldWindow.closeObjectCard() end)
    end)
elseif step == "end" then
    local lo = camp() and SCampfireSystem.instance:getLuaObjectOnSquare(camp())
    if lo then pcall(function() SCampfireSystem.instance:removeCampfire(lo) end) end
    for _, it in ipairs(ZEDQA_V2.given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("DONE")
end
