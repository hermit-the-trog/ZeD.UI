-- ZeDUI/tools/qa/zedqa_offsave.lua  (Oct 24 2026)
-- Does a save made with ZeD-UI still load with ZeD switched off, and come back
-- whole when ZeD is switched on again? (director, before a public test: testers
-- who turn ZeD off must not lose their save.) Three phases, one per launch:
--   before  ZeD on, the ZeD-QA save (through zedqa_run.ps1): the character wears
--           ZeD's steel Timez watch, carries a second one and has a third in a
--           bag (the one item ZeD adds), then the inventory is written down.
--   off     ZeD off (the ZeDQA_Probe mod runs this), a copy of that save:
--           written down again; ZeD's watches are expected to be gone, the rest
--           the same.
--   on      ZeD on again, the same copy: written down again, and ZeD's windows
--           open with its save data (journal, kill counts) still there.
-- The phase comes from the global ZEDQA_OFF_PHASE (default "before"). Each
-- writes Zomboid/Lua/zedqa_off_<phase>.txt: "T <full type> <count>" for every
-- item the character carries (bags opened), "W <location> <full type>" for
-- what is worn, "M <key>" for the character's ZeD_ save data.
-- grep "ZEDQA off".
local PHASE = rawget(_G, "ZEDQA_OFF_PHASE") or "before"
local function say(s) print("ZEDQA off " .. PHASE .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end

local function add(ft, into)
    local it = nil
    pcall(function() it = instanceItem(ft) end)
    if it then (into or p:getInventory()):AddItem(it) end
    return it
end

if PHASE == "before" then
    local w = add("Base.WristWatch_Left_DigitalTimez")
    local loc = nil
    pcall(function() loc = w:getBodyLocation() end)
    local on = false
    pcall(function() p:setWornItem(loc, w); on = p:getWornItem(loc) == w end)
    say("worn Timez " .. tostring(on))
    add("Base.WristWatch_Right_DigitalTimez")
    local bag = nil
    local items = p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "InventoryContainer") and not bag and it:getInventory():getCapacity() >= 2 and not it:getFullType():find("KeyRing") then bag = it end
    end
    if not bag then bag = add("Base.Bag_Schoolbag") end
    local b = add("Base.WristWatch_Left_DigitalTimez", bag and bag:getInventory())
    say("Timez in " .. tostring(bag and bag:getFullType()) .. " " .. tostring(b ~= nil))
end

-- write the inventory down
local counts, lines = {}, {}
local function walk(c, depth)
    local items = c:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local ft = it:getFullType()
        counts[ft] = (counts[ft] or 0) + 1
        if depth < 4 and instanceof(it, "InventoryContainer") then walk(it:getInventory(), depth + 1) end
    end
end
walk(p:getInventory(), 0)
for ft, n in pairs(counts) do lines[#lines + 1] = "T " .. ft .. " " .. n end
local worn = p:getWornItems()
for i = 0, worn:size() - 1 do
    local wi = worn:get(i)
    lines[#lines + 1] = "W " .. tostring(wi:getLocation()) .. " " .. tostring(wi:getItem() and wi:getItem():getFullType())
end
for k in pairs(p:getModData()) do
    if type(k) == "string" and k:sub(1, 4) == "ZeD_" then lines[#lines + 1] = "M " .. k end
end
table.sort(lines)
local f = getFileWriter("zedqa_off_" .. PHASE .. ".txt", true, false)
if f then
    for _, l in ipairs(lines) do f:write(l .. "\n") end
    f:close()
end
local total = 0
for _, n in pairs(counts) do total = total + n end
say("items " .. total .. ", worn " .. worn:size() .. ", written zedqa_off_" .. PHASE .. ".txt")

local zedOn = false
pcall(function() zedOn = getActivatedMods():contains("ZeD_UI") end)
say("ZeD_UI active " .. tostring(zedOn))
if PHASE == "off" then
    local inv = getPlayerInventory and getPlayerInventory(0)
    say("vanilla inventory " .. tostring(inv ~= nil) .. " visible " .. tostring(inv and inv:isVisible()))
    if zedOn then say("ERR ZeD_UI is still active") end
elseif PHASE == "on" then
    if not zedOn then say("ERR ZeD_UI is not active") end
    pcall(function()
        if not ZeD_CharacterWindow.getWindow() or not ZeD_CharacterWindow.getWindow():isVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
    end)
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow()
    say("ZeD windows " .. tostring(cw and cw:isVisible()))
end
pcall(function() getCore():TakeFullScreenshot("zqa_off_" .. PHASE .. ".png") end)
say("DONE")
