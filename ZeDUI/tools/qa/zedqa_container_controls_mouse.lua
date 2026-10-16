-- ZeDUI/tools/qa/zedqa_container_controls_mouse.lua  (Oct 16 2026)
-- Companion to zedqa_container_controls.lua, for the real mouse (gin.ps1):
-- seeds 3 nails in the pickup's bed and 2 in the bag, opens both windows on
-- the bed and logs the World window's Same type button in screen pixels
-- ("ZEDQA cm btn"), then waits. A second go-file run with ZEDQA_CM_STEP = "ask"
-- shows the row's question (a stand-in Delete all) and its Cancel; "end" takes
-- the nails back and closes the windows. grep "ZEDQA cm".
local p = getPlayer()
local pn = p:getPlayerNum()
local CT = ZeD.ContainerControls
local function say(s) print("ZEDQA cm " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cm_" .. n .. ".png") end) end
local step = ZEDQA_CM_STEP or "setup"
local function wc() return ZeD_WorldWindow.getWindow()._mainContent end
local function nails(inv) local n = 0; local it = inv:getItems(); for i = 0, it:size() - 1 do if it:get(i):getFullType() == "Base.Nails" then n = n + 1 end end; return n end

if step == "setup" then
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if v:getScriptName() == "Base.PickUpTruck" then local d = v:DistTo(p); if not bd or d < bd then best, bd = v, d end end
    end
    local part = best and (best:getPartById("TruckBed") or best:getPartById("TruckBedOpen"))
    local bed = part and part:getItemContainer()
    ZEDQA_CM = { bed = bed, given = {} }
    for _ = 1, 3 do ZEDQA_CM.given[#ZEDQA_CM.given + 1] = bed:AddItem("Base.Nails") end
    for _ = 1, 2 do ZEDQA_CM.given[#ZEDQA_CM.given + 1] = p:getInventory():AddItem("Base.Nails") end
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    local tick = 0
    local function t()
        tick = tick + 1
        if tick == 20 then
            local w = ZeD_WorldWindow.getWindow()
            for i, c in ipairs(w._containers or {}) do if c.inventory == bed then w._activeContainer = i; w._viewedContainer = nil; w._mainVisible = false end end
        end
        if tick == 60 then
            local c = wc()
            for _, h in ipairs(c._cc and c._cc.hits or {}) do
                say(string.format("btn %s %d %d %d %d", h.key, c:getAbsoluteX() + h.x, c:getAbsoluteY() + h.y, h.w, h.h))
            end
            say("bed nails " .. nails(bed) .. " bag nails " .. nails(p:getInventory()))
            Events.OnTick.Remove(t)
        end
    end
    Events.OnTick.Add(t)
elseif step == "count" then
    say("bed nails " .. nails(ZEDQA_CM.bed) .. " bag nails " .. nails(p:getInventory()) .. " marks " .. tostring(wc()._ccMarks ~= nil))
elseif step == "ask" then
    local c = wc()
    c._cc.ask = { ask = "Delete all 3 items for good?", run = function() say("the yes ran") end }
    local tick = 0
    local function t()
        tick = tick + 1
        if tick == 10 then shot("02_ask_row"); local L = c._cc.layout; say("ask row " .. tostring(L and L.question) .. " buttons " .. tostring(L and #L.rects)) end
        if tick == 15 then CT.press(c, 1); say("after Cancel: ask " .. tostring(c._cc.ask ~= nil)) end
        if tick == 20 then c._cc.ask = { ask = "Delete all 3 items for good?", run = function() say("the yes ran") end } end
        if tick == 25 then CT.press(c, 2); say("after Delete all: ask " .. tostring(c._cc.ask ~= nil)); Events.OnTick.Remove(t) end
    end
    Events.OnTick.Add(t)
elseif step == "end" then
    for _, it in ipairs(ZEDQA_CM.given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("DONE bed nails " .. nails(ZEDQA_CM.bed) .. " bag nails " .. nails(p:getInventory()))
end
