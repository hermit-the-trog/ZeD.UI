-- ZeDUI/tools/qa/gallery_v3_b2.lua  (Oct 21 2026)
-- Workshop gallery v3, second batch (director's review): after gallery_v3_core.lua, _reveal
-- and _stage, ZeD on, high contrast + PZ Teal. Full 4K screenshots zed_<nn>_<scene>.png:
--   60    Skills tab with believable levels and part-way progress (the perks put back after)
--   61-63 the windows' footer quick toggles (theme dot, accent dot, text size A, reset R):
--         both footers, then the World window's accent dot before / after one press (the
--         window's own accent, set in memory only and put back)
--   65    Identity tab
--   66-72 Thermal tab, its seven views, the clothes wet and the air cold (put back)
--   76-77 the dash: by day with the headlights off, by night (real darkness) with them on
--   78-80 the mini watch on the belt for three models (CaZio digital, Timez, classic gold)
-- Window boxes are printed ("box ...") for the inventory. "ZEDQA g3b ..." ending "DONE".
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA g3b ERR run core and stage first"); print("ZEDQA g3b DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA g3b ERR ZeD is not loaded"); print("ZEDQA g3b DONE"); return end
local S = G.newSeq("g3b", 900000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local B = { lock = nil, perks = {}, wet = {}, was = {} }
B.was.watch = ZeD.Settings.watchPlaceOption:getValue()
function B.CW() return CWm.getWindow() end
function B.WW() return WWm.getWindow() end
function B.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
function B.place()
    local c, w = B.CW(), B.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) or w._rolled then return false end
    if not B.lock then
        local gap = ZeD.T.px(8)
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        B.lock = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap }
    end
    c._anchorRightEdge = B.lock.right
    c:setX(B.lock.right - c:getWidth()); w:setX(B.lock.left)
    c:setY(0); w:setY(0)
    return true
end
function B.openPair()
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    B.place()
end
function B.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function B.charTab(id) local w = B.CW(); return w and B.goTab(w, w._tabStripPanel, id) end
function B.worldTab(id) local w = B.WW(); return w and B.goTab(w, w._actionTabStrip, id) end
function B.box(tag, win)
    if win and win:isVisible() then
        say(string.format("box %s %s %d,%d-%d,%d", tag, tostring(win.title or win._activeTab), win:getX(), win:getY(), win:getX() + win:getWidth(), win:getY() + win:getHeight()))
        for i, r in ipairs(win._themeControlRects or {}) do
            say(string.format("box %s footer%d %d,%d-%d,%d", tag, i, r.x, r.y, r.x + r.w, r.y + r.h))
        end
    end
end
function B.boxes(tag) B.box(tag .. " char", B.CW()); B.box(tag .. " world", B.WW()) end
function B.shot(name) S.shot(name); B.boxes(name) end

-- skills: a few perks at believable levels, part-way into the next
local SK = { { "Carpentry", 4, 0.55 }, { "Cooking", 3, 0.3 }, { "Mechanics", 2, 0.7 }, { "Aiming", 5, 0.4 }, { "Maintenance", 3, 0.6 },
             { "LongBlunt", 6, 0.25 }, { "SmallBlade", 2, 0.5 }, { "PlantScavenging", 4, 0.65 }, { "Doctor", 3, 0.45 },
             { "Electricity", 2, 0.2 }, { "Sprinting", 3, 0.5 }, { "Lightfoot", 2, 0.8 }, { "Sneak", 3, 0.35 }, { "Tailoring", 1, 0.6 } }
function B.setSkills()
    local xp = p:getXp()
    local n = 0
    for _, s in ipairs(SK) do
        local perk = Perks[s[1]]
        if perk then
            local ok = pcall(function()
                B.perks[#B.perks + 1] = { perk = perk, lvl = p:getPerkLevel(perk), xp = xp:getXP(perk) }
                p:setPerkLevelDebug(perk, s[2])
                xp:setXPToLevel(perk, s[2])
                local pk = PerkFactory.getPerk(perk)
                local span = pk:getTotalXpForLevel(s[2] + 1) - pk:getTotalXpForLevel(s[2])
                xp:AddXPNoMultiplier(perk, span * s[3])
            end)
            if ok then n = n + 1 end
        end
    end
    say("skills set: " .. n .. "/" .. #SK)
end
function B.restoreSkills()
    local xp = p:getXp()
    local n = 0
    for i = #B.perks, 1, -1 do
        local s = B.perks[i]
        local ok = pcall(function()
            p:setPerkLevelDebug(s.perk, s.lvl)
            xp:setXPToLevel(s.perk, s.lvl)
            local now = xp:getXP(s.perk)
            if s.xp > now then xp:AddXPNoMultiplier(s.perk, s.xp - now) end
        end)
        if ok then n = n + 1 end
    end
    B.perks = {}
    say("skills back: " .. n)
end

-- the mini watch: one model worn on the left wrist in place of the kit's
function B.watch(name)
    local cur, loc = nil, nil
    pcall(function()
        local worn = p:getWornItems()
        for i = 0, worn:size() - 1 do
            local wi = worn:get(i)
            if instanceof(wi:getItem(), "AlarmClockClothing") then cur = wi:getItem(); loc = wi:getLocation() end
        end
    end)
    if not B.kitWatch then B.kitWatch, B.kitLoc = cur, loc end
    if cur then p:removeWornItem(cur, false) end
    if not name then
        if B.kitWatch then p:setWornItem(B.kitLoc, B.kitWatch) end
    else
        local it = G.inv:AddItem("Base.WristWatch_Left_" .. name)
        if it then p:setWornItem(loc or it:getBodyLocation(), it) end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() local hb = getPlayerHotbar(pn); if hb then hb:refresh() end end)
end

-- ===========================================================================
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    G.stand()
    pcall(ZeD.Settings.reapplyFromOptions)
    say("theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
    ZeD.Settings.watchPlaceOption:setValue(1)
    B.setSkills()
    B.openPair()
end)
S.zoomTo(1.0)

-- 60 skills
S.step(2, function() B.charTab("skills") end)
S.step(40, function() B.place(); G.faceFront() end)
S.step(20, function() B.shot("zed_60_skills_progress") end)
S.step(2, function() B.restoreSkills(); B.charTab("loot"); B.worldTab("loot") end)

-- 61-63 the footers' quick toggles
S.step(40, function() B.place() end)
S.step(20, function() B.shot("zed_61_footer_toggles") end)
S.step(2, function()
    local w = B.WW()
    B.was.wAccent = w._accentKey
    say("world accent key before: " .. tostring(w._accentKey))
end)
S.step(10, function() B.shot("zed_62_footer_accent_before") end)
S.step(2, function()
    -- one press of the World window's accent dot: its own accent steps on (in memory only)
    local w = B.WW()
    local S2 = ZeD.Settings
    local keys = S2.accentKeys
    if w._accentKey == nil then w._accentKey = keys[1] else w._accentKey = S2.cycleNext(keys, w._accentKey) end
    say("world accent key after: " .. tostring(w._accentKey))
end)
S.step(20, function() B.shot("zed_63_footer_accent_after") end)
S.step(2, function() local w = B.WW(); w._accentKey = B.was.wAccent end)

-- 65 identity
S.step(10, function() B.charTab("identity") end)
S.step(40, function() B.place() end)
S.step(20, function() B.shot("zed_65_identity") end)

-- 66-72 thermal: wet clothes, cold air
S.step(2, function()
    pcall(function()
        local worn = p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:get(i):getItem()
            if instanceof(it, "Clothing") then pcall(function() it:setWetness(70) end) end
        end
    end)
    G.climSet({ TEMPERATURE = 2.0, WIND_INTENSITY = 0.6 })
    B.charTab("thermal")
end)
S.waitMs(4000)
local VIEWS = { "skin", "response", "vessels", "shiver", "insulation", "wind", "wetness" }
for i, v in ipairs(VIEWS) do
    S.step(2, function() local c = B.CW(); c._thermalView = i end)
    S.step(25, function() B.place() end)
    S.step(10, function() B.shot(string.format("zed_%02d_thermal_%s", 65 + i, v)) end)
end
S.step(2, function()
    local c = B.CW(); c._thermalView = 1
    pcall(function()
        local worn = p:getWornItems()
        for i = 0, worn:size() - 1 do local it = worn:get(i):getItem(); if instanceof(it, "Clothing") then pcall(function() it:setWetness(0) end) end end
    end)
    G.dayAgain()
    G.day()
    B.charTab("loot")
end)

-- 76-77 the dash: day with the lights off, night with them on
S.step(2, function() B.closePair() end)
S.step(2, function()
    pcall(function() G.car:enter(0, p) end)
    B.entered = p:getVehicle() ~= nil
    if B.entered then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
end)
S.step(30, function() if B.entered then pcall(function() G.car:setKeysInIgnition(true) end) end end)
local ES = { tries = 0, last = -9999 }
S.poll(10, 1500, function()
    if not B.entered then return true end
    local run = false
    pcall(function() run = G.car:isEngineRunning() end)
    if run then return true end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    if not (q and q.queue and #q.queue > 0) and S.tick - ES.last > 120 and ES.tries < 5 then
        ES.tries = ES.tries + 1; ES.last = S.tick
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
    end
    return false
end)
local function lights(on)
    local v = G.car
    local cur = false
    pcall(function() cur = v:getHeadlightsOn() end)
    if cur ~= on then pcall(function() ISVehicleMenu.onToggleHeadlights(p) end) end
end
S.step(30, function() lights(false); local d = ZeD.Dashboard and ZeD.Dashboard.getInstance(); if d and d._st and not d._st.radioOn then d:_fire("pwr", false) end end)
S.step(120, function()
    local on = false; pcall(function() on = G.car:getHeadlightsOn() end)
    say("day: headlights " .. tostring(on))
    if B.entered then S.shot("zed_76_dash_day") else S.err("zed_76_dash_day", "not seated") end
end)
S.step(2, function() if B.entered then G.night() end end)
S.waitMs(5000)
S.step(2, function() lights(true) end)
S.waitMs(3000)
S.step(2, function()
    local on = false; pcall(function() on = G.car:getHeadlightsOn() end)
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    say(string.format("night: headlights %s | dash lights %s hiBeam %s | time %.2f | daylight %s",
        tostring(on), tostring(d and d._st and d._st.lights), tostring(d and d._st and d._st.hiBeam), G.gt:getTimeOfDay(),
        tostring(getClimateManager():getDayLightStrength())))
    if B.entered then S.shot("zed_77_dash_night") end
end)
S.step(2, function()
    lights(false)
    G.dayAgain()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end)
S.step(40, function() G.stand(); G.openTrunk(G.car); G.faceFront() end)

-- 78-80 the mini watch on the belt, three models
S.zoomTo(0.5)
for i, name in ipairs({ "DigitalTimez", "ClassicGold", "DigitalRed" }) do
    S.step(2, function() B.watch(name) end)
    S.step(60, function() G.faceFront() end)
    S.step(10, function() S.shot(string.format("zed_%02d_belt_watch_%s", 77 + i, name)) end)
end
S.step(2, function() B.watch(nil) end)
S.zoomTo(1.0)
S.step(10, function()
    ZeD.Settings.watchPlaceOption:setValue(B.was.watch)
    if #B.perks > 0 then B.restoreSkills() end
    B.openPair()
    B.charTab("loot"); B.worldTab("loot")
end)
S.start()
