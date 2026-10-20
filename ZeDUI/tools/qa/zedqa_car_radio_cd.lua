-- ZeDUI/tools/qa/zedqa_car_radio_cd.lua  (Oct 15 2026)
-- The car radio's CD deck, live on the ZeD-QA save: a retail CD given one of
-- vanilla's recordings (spawned discs get theirs from the loot tables), the
-- slot's list of CDs carried, insert through vanilla's media action, play
-- (the display's clock and title), eject; then the ValuTech's tape. Reloads
-- ZeD_CarRadio.lua first if Zomboid/Lua/zed_reload_cr.lua is there (a copy of
-- it). Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA cd".

local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA cd " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cd_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local RO, CR = ZeD.RadioOps, ZeD.CarRadio
local pickup, cd
local function near(pred, maxD)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if pred(v) then local d = v:DistTo(p); if d < maxD and (not bd or d < bd) then best, bd = v, d end end
    end
    return best
end
-- the pickup spawned beside the character when the QA save's own is not loaded near it (the character is left
-- wherever the last run ended); removed at the end
local spawned = {}
local dead = false
local finalAt = nil
-- (an abort skips the other steps and jumps the tick counter to just before the final one)
local function abort(msg) say("ERR " .. msg); dead = true; if finalAt then tick = finalAt - 2 end end
local function final(n, fn) finalAt = n; steps[#steps + 1] = { n = n, fn = fn, final = true } end   -- runs even after an abort
local function spawn(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then say("no square for " .. script); return nil end
    local ok, v = pcall(addVehicleDebug, script, IsoDirections.N, nil, sq)
    if ok and v then spawned[#spawned + 1] = v; say("spawned " .. script .. " beside the character"); return v end
    return nil
end
local function part() return pickup and pickup:getPartById("Radio") end
local function prop() return CR.props[pn] end
local function report(tag)
    local st = part() and RO.read(part())
    if not st then say(tag .. " no radio"); return end
    say(string.format("%s kind=%s on=%s ch=%s media=%s playing=%s title=%s cdMs=%s", tag, st.kind, tostring(st.on), tostring(st.channel),
        tostring(st.hasMedia), tostring(st.playing), tostring(st.mediaTitle), tostring(st.cdMs)))
end
local function fit(ft)
    local pt = part()
    pt:setInventoryItem(instanceItem(ft))
    Vehicles.InstallComplete.Radio(pickup, pt)
    say("fit " .. ft)
end

at(1, function()
    pickup = near(function(v) return v:getScriptName() == "Base.PickUpTruck" end, 25)
    if not pickup then pickup = spawn("Base.PickUpTruck", -4, 0) end
    if not pickup then abort("no pickup within 25 tiles and the spawn failed") end
end)
at(2, function()
    local r = getFileReader("zed_reload_cr.lua", false)
    if r then
        local lines, l = {}, r:readLine()
        while l do lines[#lines + 1] = l; l = r:readLine() end
        r:close()
        CR.closeFor(pn); CR.props[pn] = nil
        local fn, err = loadstring(table.concat(lines, "\n"))
        if fn then local ok, e = pcall(fn); say("reloaded ZeD_CarRadio ok=" .. tostring(ok) .. " " .. tostring(e)) else say("reload parse " .. tostring(err)) end
    end
    if pickup and part() and not part():getInventoryItem() then fit("Base.RadioRed") end   -- a spawned pickup comes without one
    say("pickup " .. tostring(pickup) .. " radio=" .. tostring(part() and part():getInventoryItem() and part():getInventoryItem():getFullType()))
    say("hand font height " .. tostring(ZeD.Text.realTM():getFontHeight(UIFont.Handwritten)))
end)
-- (a spawned pickup gets a moment to settle before the character gets in)
at(26, function() pickup:enter(0, p); triggerEvent("OnEnterVehicle", p) end)
at(40, function()
    ISVehicleMenu.onSignalDevice(p, part())
    local dd = part():getDeviceData()
    if not dd:getIsTurnedOn() then RO.power(p, part()) end
    RO.setChannel(p, part(), 93200)
    cd = p:getInventory():AddItem("Base.Disc_Retail")
    local list = getZomboidRadio():getRecordedMedia():getAllMediaForCategory("CDs")
    say("vanilla CD recordings: " .. tostring(list and list:size()))
    if list and list:size() > 0 then cd:setRecordedMediaData(list:get(ZombRand(list:size()))) end
    say("cd isRecordedMedia=" .. tostring(cd:isRecordedMedia()) .. " mediaType=" .. tostring(cd:getMediaType()) .. " name=" .. tostring(cd:getDisplayName()))
    say("cds carried: " .. #RO.cds(p, part()))
end)
at(60, function() local pr = prop(); if pr then pr:cdList() end end)
at(75, function() shot("c01_cdlist") end)
at(80, function()
    local ctx = getPlayerContextMenu(pn); if ctx and ctx:isVisible() then ctx:closeAll() end
    local pr = prop(); if pr then pr:onPickCD(cd) end
end)
at(180, function() report("inserted") end)
at(185, function() say("play ok=" .. tostring(RO.playStop(p, part()))) end)
at(400, function() report("playing"); shot("c02_cd_playing") end)
at(405, function() RO.playStop(p, part()); say("eject ok=" .. tostring(RO.eject(p, part()))) end)
at(500, function() report("ejected"); say("disc back in inventory: " .. tostring(p:getInventory():contains(cd))); shot("c03_ejected") end)
at(505, function() fit("Base.RadioBlack"); RO.power(p, part()); RO.setChannel(p, part(), 98400) end)
at(530, function() report("valutech"); shot("c04_valutech_tape") end)
at(535, function()
    fit("Base.RadioRed")
    part():getDeviceData():setIsTurnedOn(false)
    CR.takeEscape()
    p:getInventory():Remove(cd)
end)
at(545, function() pickup:exit(p); triggerEvent("OnExitVehicle", p) end)
final(560, function()
    if pickup and p:getVehicle() == pickup then pickup:exit(p); triggerEvent("OnExitVehicle", p) end
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    spawned = {}
    say("DONE" .. (dead and " (aborted)" or ""))
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick and (s.final or not dead) then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 580 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
