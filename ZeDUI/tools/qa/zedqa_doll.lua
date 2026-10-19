-- ZeDUI/tools/qa/zedqa_doll.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the Equip tab's doll view. Wears a cap, a jacket
-- and a formal shirt (layers), shows the doll, opens a slot's card by the
-- simulated pad, steps its layers, B back, then puts everything back (the
-- view option included). Screenshots zqa_doll_*.png. grep "ZEDQA doll".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det, Doll = ZeD.Input.Focus, ZeD.Input.Detector, ZeD.EquipDoll
local function say(s) print("ZEDQA doll " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function zone(w, name)
    for i, z in ipairs(w._focusRing or {}) do if z.zone == name then return i, z end end
end
local function where(tag)
    local w = cw(); local z = Focus.getFocusedZone(w); local e = Focus.getFocusedElement(w)
    say(tag .. ": zone=" .. tostring(z and z.zone) .. " el=" .. tostring(e and e.id) .. " sel=" .. tostring(w._equipSelected) .. " layer=" .. tostring(w._equipLayer))
end
local function focusId(id)
    local w = cw(); local zi, z = zone(w, "charTabContent")
    for ei, el in ipairs(z and z.elements or {}) do
        if el.id == id then w._focusIdx = zi; z.focusedElementIdx = ei; if el.onFocus then el.onFocus(w, el) end; return el end
    end
end
local origView = Doll.view()
local added = {}
local function wear(t)
    local it = p:getInventory():AddItem(t)
    if it then p:setWornItem(it:getBodyLocation(), it); added[#added + 1] = it end
end
at(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
at(20, function()
    wear("Base.Hat_BaseballCapBlue"); wear("Base.Jacket_Padded"); wear("Base.Shirt_FormalWhite")
    triggerEvent("OnClothingUpdated", p)
    Det.setLockedMode(Det.MODE_GAMEPAD); Focus.claimFocus(cw())
    tab("equip"); Doll.setView("doll")
end)
at(60, function()
    local w = cw()
    local ids = {}
    for _, z in ipairs(w._equipSlotZones or {}) do ids[#ids + 1] = z.type end
    local ph = w._equipDollPhoto
    say("doll shown " .. tostring(w._equipDollShown) .. " | slots " .. #ids .. " {" .. table.concat(ids, ",") .. "} | belt empties " .. #(w._equipBeltZones or {})
        .. " | photo " .. (ph and (ph.x .. "," .. ph.y .. " " .. ph.w .. "x" .. ph.h) or "nil") .. " | lines " .. #(w._equipDollLines or {})
        .. " | model visible " .. tostring(w._identityModel and w._identityModel:isVisible()) .. " | layer visible " .. tostring(w._equipDollLayer and w._equipDollLayer:isVisible()))
    local _, z = zone(w, "charTabContent")
    local els = {}
    for _, e in ipairs(z and z.elements or {}) do if not tostring(e.id):find("equippart") then els[#els + 1] = e.id end end
    say("pad targets: " .. table.concat(els, ","))
end)
at(70, function() pcall(function() getCore():TakeFullScreenshot("zqa_doll_1.png") end) end)
-- the pad: the torso slot (two layers), A, the card
at(90, function() local el = focusId("equipslot:doll:torso"); where("focus torso"); if el then el.onActivate(cw(), el) end end)
at(130, function()
    local w = cw(); local _, z = zone(w, "charTabContent")
    local els = {}
    for _, e in ipairs(z and z.elements or {}) do els[#els + 1] = e.id end
    say("card targets: " .. table.concat(els, ","))
    where("card open")
end)
at(140, function() pcall(function() getCore():TakeFullScreenshot("zqa_doll_2.png") end) end)
at(150, function() local el = focusId("equipcard:__layer_1"); where("focus Inner"); if el then el.onActivate(cw(), el) end end)
at(170, function() where("after Inner (expect layer 2)") end)
at(175, function() pcall(function() getCore():TakeFullScreenshot("zqa_doll_3.png") end) end)
at(190, function()
    local w = cw(); local e = Focus.getFocusedElement(w)
    if e and e.onCancel then e.onCancel(w, e) end
end)
at(200, function() where("after B (expect sel=nil, el=equipslot:doll:torso)") end)
-- the pad moves among the slots
at(210, function() focusId("equipslot:doll:head"); Focus.dispatchJoypadDir(cw(), "down"); where("head then down") end)
at(220, function() Focus.dispatchJoypadDir(cw(), "right"); where("then right (expect back)") end)
at(230, function() Focus.dispatchJoypadDir(cw(), "down"); where("then down (expect belt)") end)
at(235, function() Focus.dispatchJoypadDir(cw(), "left"); where("then left (expect neck)") end)
at(240, function() Focus.dispatchJoypadDir(cw(), "left"); where("then left (leaves the doll)") end)
at(250, function()
    for _, it in ipairs(added) do p:removeWornItem(it); p:getInventory():Remove(it) end
    triggerEvent("OnClothingUpdated", p)
    Doll.setView(origView)
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say("view restored to " .. origView .. " | DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 255 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
