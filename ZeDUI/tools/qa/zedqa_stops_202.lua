-- ZeDUI/tools/qa/zedqa_stops_202.lua  (Nov 14 2026, QA): one look for punch list 202, at Build's request. An empty
-- microwave beside the character, opened as the World window's container; the pad on its header's view button
-- (Down over the empty list), then every stop the window has (zone, focusable, id and bounds, both the zone's own and
-- the flat list's), then one spatial Down and where it landed. No checks; the data is for Build. grep "ZEDQA s202".
local function say(s) print("ZEDQA s202 " .. tostring(s)) end
local p = getPlayer()
local Focus = ZeD.Input.Focus
local jd = JoypadState.players[1]
if not jd then
    for i = 0, 15 do
        local c = JoypadState.controllers[i]
        if c and c.connected then
            pcall(function() triggerEvent("OnJoypadActivate", i) end)
            jd = JoypadState.players[1] or JoypadState.joypads[1]
            if jd and not JoypadState.players[1] then pcall(function() p:setJoypadBind(i); jd.player = 0; JoypadState.players[1] = jd end) end
            break
        end
    end
end
jd = JoypadState.players[1] or { player = 0 }
local function n(v) return v == nil and "nil" or (type(v) == "number" and string.format("%d", math.floor(v + 0.5)) or tostring(v)) end
local so = getSandboxOptions()
local elec = so and so:getOptionByName("ElecShutModifier")
local elecWas = elec and elec:getValue()
local hydroWas = getWorld():isHydroPowerOn()
local micro, msq, w
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function()
    if elec then elec:setValue(99999); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(true)
    msq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), math.floor(p:getZ()))
    micro = IsoStove.new(getCell(), msq, getSprite("appliances_cooking_01_24"))
    pcall(function() micro:createContainersFromSpriteProperties() end)
    msq:AddSpecialObject(micro)
    if micro:getObjectIndex() < 0 then pcall(function() msq:AddTileObject(micro) end) end
    local c = micro:getContainer()
    say("microwave placed, container " .. tostring(c and c:getType()) .. ", items " .. tostring(c and c:getItems():size()) ..
        ", powered " .. tostring(c and c:isPowered()))
    pcall(function() if not ZeD_WorldWindow.getWindow(0) or not ZeD_WorldWindow.getWindow(0):isReallyVisible() then ZeD.toggleBothPaired(0) end end)
end)
at(1800, function()
    w = ZeD_WorldWindow.getWindow(0)
    say("selectContainer " .. tostring(ZeD_WorldWindow.selectContainer(micro:getContainer(), 30, 0)))
end)
at(3500, function()
    Focus.claimFocus(w)
    local c = w._containers and w._containers[w._activeContainer]
    say("active container " .. n(w._activeContainer) .. " is the microwave " .. tostring(c and c.inventory == micro:getContainer()) ..
        ", main visible " .. tostring(w._mainVisible))
    local hdr
    for _, s in ipairs(Focus.flatElements(w)) do if s.el and s.el.isViewToggle then hdr = s; break end end
    say("header view stop: " .. tostring(hdr and (hdr.zone .. " " .. tostring(hdr.id))))
    if hdr then Focus.focusWhere(w, hdr.zone, function(e) return tostring(e.id) == tostring(hdr.id) end) end
end)
at(4300, function()
    local z, el = Focus.getFocusedZone(w), Focus.getFocusedElement(w)
    say(string.format("FOCUSED zone=%s id=%s isViewToggle=%s x=%s y=%s w=%s h=%s", tostring(z and z.zone), tostring(el and el.id),
        tostring(el and el.isViewToggle), n(el and el.x), n(el and el.y), n(el and el.w), n(el and el.h)))
    for zi, zone in ipairs(w._focusRing or {}) do
        local pnl = zone.panel or zone._panel or zone.source
        say(string.format("ZONE %d %s focusable=%s elements=%d panel=%s", zi, tostring(zone.zone), tostring(zone.focusable),
            zone.elements and #zone.elements or 0, tostring(pnl and (pnl._zedLabel or pnl.Type or pnl))))
        for ei, e in ipairs(zone.elements or {}) do
            say(string.format("  el %d id=%s x=%s y=%s w=%s h=%s%s", ei, tostring(e.id), n(e.x), n(e.y), n(e.w), n(e.h),
                e.isViewToggle and " isViewToggle" or ""))
        end
    end
    for k, s in ipairs(Focus.flatElements(w)) do
        say(string.format("FLAT %d zone=%s id=%s x=%s y=%s w=%s h=%s", k, tostring(s.zone), tostring(s.id), n(s.x), n(s.y), n(s.w), n(s.h)))
    end
    Focus.dispatchJoypadDir(w, "down", jd)
end)
at(5000, function()
    local z, el = Focus.getFocusedZone(w), Focus.getFocusedElement(w)
    say("AFTER DOWN zone=" .. tostring(z and z.zone) .. " id=" .. tostring(el and el.id))
    pcall(function() getCore():TakeFullScreenshot("zqa_s202.png") end); say("picture zqa_s202.png")
    Focus.dispatchJoypadDir(w, "up", jd)
end)
at(5400, function()
    local el = Focus.getFocusedElement(w)
    say("AFTER UP id=" .. tostring(el and el.id))
end)
at(5600, function()
    pcall(function() msq:transmitRemoveItemFromSquare(micro) end)
    pcall(function() msq:RemoveTileObject(micro) end)
    if elec and elecWas then elec:setValue(elecWas); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(hydroWas)
    say("DONE")
end)
local function tick()
    local now = getTimestampMs()
    if not t0 then t0 = now end
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
