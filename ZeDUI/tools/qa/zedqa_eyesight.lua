-- ZeDUI/tools/qa/zedqa_eyesight.lua  (Oct 25 2026)
-- Diagnostic: why the QA character's world draws blurred past a short distance (the
-- gallery reshoot came out soft; director: "does the character need glasses?").
-- Logs the eyesight state, then shoots the same view three ways: as it is, wearing
-- prescription glasses, and with the view cone's opacity at 0. Everything is put back.
-- Screenshots/zqa_eye_*.png; grep "ZEDQA eye".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA eye " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_eye_" .. n .. ".png") end); say("shot " .. n) end
local ct = p:getCharacterTraits()
local function has(k) local t = CharacterTrait[k]; local ok, v = pcall(function() return t and ct:get(t) end); return ok and v end
local perf = getPerformance()
local coneWas = perf:getViewConeOpacity()
local faceWas, glasses
local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(10, function()
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    local on = {}
    local defs = CharacterTraitDefinition.getTraits()
    for i = 0, defs:size() - 1 do
        local t = defs:get(i):getType()
        local ok, v = pcall(function() return ct:get(t) end)
        if ok and v then on[#on + 1] = tostring(t) end
    end
    say("traits on (" .. #on .. "): " .. table.concat(on, " "))
    say("SHORT_SIGHTED " .. tostring(has("SHORT_SIGHTED")) .. " | EAGLE_EYED " .. tostring(has("EAGLE_EYED")) .. " | view cone opacity " .. tostring(coneWas))
    local worn = {}
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do worn[#worn + 1] = tostring(wi:get(i):getLocation()) .. "=" .. wi:get(i):getItem():getFullType() end
    say("worn: " .. table.concat(worn, " "))
    local sm = getSearchMode()
    say("search overlay enabled " .. tostring(sm:isEnabled(pn)) .. " override " .. tostring(sm:isOverride(pn)))
end)
step(30, function() shot("1_as_is") end)
local loc
step(5, function()
    glasses = p:getInventory():AddItem("Base.Glasses_Prescription")
    loc = glasses:getBodyLocation()
    faceWas = p:getWornItem(loc)
    p:setWornItem(loc, glasses)
    say("wearing " .. tostring(p:getWornItem(loc) and p:getWornItem(loc):getFullType()) .. " (was " .. tostring(faceWas and faceWas:getFullType()) .. ")")
end)
step(40, function() shot("2_glasses") end)
step(5, function()
    p:setWornItem(loc, faceWas)
    pcall(function() p:getInventory():Remove(glasses) end)
    perf:setViewConeOpacity(0)
end)
step(40, function() shot("3_cone_0") end)
step(5, function()
    perf:setViewConeOpacity(coneWas)
    say("put back: eyes " .. tostring(faceWas and faceWas:getFullType()) .. ", cone " .. tostring(perf:getViewConeOpacity()))
    say("DONE")
end)

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
