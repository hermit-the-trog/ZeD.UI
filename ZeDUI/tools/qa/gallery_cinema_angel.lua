-- ZeDUI/tools/qa/gallery_cinema_angel.lua  (Nov 11 2026, QA; the gallery plan v2, shots 1 and 6): Angel's two cinema
-- breaks, the gallery's opener and closer. Light + Blue (his movie's look, the director's choice; the closer at night too).
-- Built on gallery_cinema_laura.lua / gallery_cinema_lib.lua. grep "ZEDQA cang".
--   CANG_MODE = "open" (the default): the Fossoil at West Point in the morning, Angel behind the counter. Runs on the
--     ZeD-QA save after gallery_story_stage.lua (the store, his kit, the shelves; gallery_story_teardown.lua after puts
--     it all back): cinema_run2.ps1 -Manifest cinema_angel_open.txt
--     cin_ang_open.png   the Character window on Loot with one source open (his backpack), the World window on Loot
--                        with the store's shelves open
--   CANG_MODE = "close" (gallery_cinema_angel_close_mode.lua sets it): night on the local test server, Angel face to
--     face with the other players (real clients, cinema_angel_close.ps1 starts them; gallery_cinema_angel_guest.lua
--     stands each one in front of him). Runs on the admin client (the 4K window, ZeD at 1.75x).
--     cin_ang_close.png  the Character window on Server, the World window on Loot
local C = CIN
local S = C.seq("cang")
local p = getPlayer()
local pn = p:getPlayerNum()
local MODE = CANG_MODE or "open"
local A = { cols = {} }
local function colOn(win, inv)
    for i, cc in ipairs(win and win._containers or {}) do
        if cc.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
local DIRN = { ["1,0"] = "E", ["-1,0"] = "W", ["0,1"] = "S", ["0,-1"] = "N" }

if MODE == "open" then
    local ST = STORY
    if not (ST and ST.ready and ST.P) then print("ZEDQA cang ERR run gallery_story_stage.lua first"); print("ZEDQA cang DONE"); return end
    local P = ST.P
    S.step(5, function() C.look("light", "blue"); C.noWindows(); if getGameSpeed() <= 0 then setGameSpeed(1) end end)
    S.step(10, function()
        C.time(8.0)          -- the morning
        C.clearSky()
        pcall(function() ST.queueZombies(false) end)
        -- (Nov 12 2026, the retake: no zombies in front of the store or behind the belt) the stage's passive zombies taken
        -- away now (the teardown finds them gone), and the native ones within 30 squares too (the QA save keeps that)
        local gone, nat = 0, 0
        for _, z in ipairs(ST.A.zombies or {}) do ST.removeZombie(z); gone = gone + 1 end
        ST.A.zombies = {}
        pcall(function()
            local l, rm = getCell():getZombieList(), {}
            for i = 0, l:size() - 1 do
                local z = l:get(i)
                if math.abs(z:getX() - P.clerk[1]) < 30 and math.abs(z:getY() - P.clerk[2]) < 30 then rm[#rm + 1] = z end
            end
            local keep = {}
            for _, e in ipairs(ST.A.native or {}) do
                local hit = false
                for _, z in ipairs(rm) do if e.z == z then hit = true end end
                if not hit then keep[#keep + 1] = e end
            end
            ST.A.native = keep
            for _, z in ipairs(rm) do ST.removeZombie(z); nat = nat + 1 end
        end)
        S.say("zombies taken away: " .. gone .. " of the stage's, " .. nat .. " near the store")
        ST.tpSq(P.clerk)
        A.face = DIRN[tostring(P.queueDir[1]) .. "," .. tostring(P.queueDir[2])] or "E"
        S.say(string.format("behind the counter at %d,%d facing %s (counter %d,%d)", P.clerk[1], P.clerk[2], A.face, P.counter[1], P.counter[2]))
    end)
    C.lookAround(S, "S")
    S.step(5, function() p:setDir(IsoDirections[A.face or "E"]) end)
    C.pointerAway(S)
    C.zoom(S, 0.5)       -- (Nov 12 2026: a step closer than the first take's 0.75, Angel larger)
    S.step(30, function() C.windows("loot", "loot") end)
    S.step(60, function()
        local w = ZeD_WorldWindow.getWindow()
        for _, cc in ipairs(w and w._containers or {}) do
            for _, e in ipairs((ST.F and ST.F.shelves) or {}) do
                if cc.inventory == e.inv and #A.cols < 2 then A.cols[#A.cols + 1] = cc.inventory end
            end
        end
        A.back = ST.bags and ST.bags.back and ST.bags.back:getInventory()
        S.say("shelves in the World window's reach: " .. #A.cols .. " | backpack " .. tostring(A.back ~= nil))
    end)
    S.poll(10, 60, function()
        local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        local done = true
        if A.back and not colOn(c, A.back) then ZeD_CharacterWindow.toggleColumn(A.back); done = false end
        for _, inv in ipairs(A.cols) do if not colOn(w, inv) then ZeD_WorldWindow.toggleColumn(inv); done = false end end
        return done
    end)
    S.step(90, function() p:setDir(IsoDirections[A.face or "E"]) end)
    C.whenStill(S, function()
        local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        local zn = 0
        pcall(function()
            local l = getCell():getZombieList()
            for i = 0, l:size() - 1 do local z = l:get(i); if math.abs(z:getX() - p:getX()) < 30 and math.abs(z:getY() - p:getY()) < 30 then zn = zn + 1 end end
        end)
        S.say(string.format("columns: char %d world %d | tabs %s / %s | time %.2f | zoom %s | zombies within 30: %d", #(c._mcSelected or {}), #(w._mcSelected or {}), tostring(c._activeTab), tostring(w._activeTab), getGameTime():getTimeOfDay(), tostring(C.core:getZoom(0)), zn))
        C.boxes(S, "ang_open")
        C.shot(S, "ang_open")
    end)
    S.step(20, function()
        local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        if A.back and colOn(c, A.back) then ZeD_CharacterWindow.toggleColumn(A.back) end
        for _, inv in ipairs(A.cols) do if colOn(w, inv) then ZeD_WorldWindow.toggleColumn(inv) end end
    end)
    S.step(20, function() C.noWindows(); S.say("DONE") end)
    S.run()
    return
end

-- ---------------------------------------------------------------------------------------------- close: the server
local Sc = ZeD.Scale
S.step(5, function()
    -- ZeD at 1.75x for the 4K window (the runner sets it only for its fullscreen mode; put back at the end)
    if Sc and Sc.root and math.abs(Sc.root() - 1.75) > 0.01 then A.scaleWas = Sc.override; Sc.override = 1.75; Sc.refresh(); ZeD.applyTheme(); A.scaled = true end
    C.look("light", "blue")
    C.noWindows()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    -- (Nov 12 2026, the retake) the full 4K screen: the 3840x2160 window was 3840x2135 inside its title bar, so the
    -- admin goes fullscreen as the game's own Display options do (cinema_angel_close.ps1 brings its window to the front
    -- first; pzrestorewin.ps1 puts options.ini back after)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    if sh ~= 2160 or sw ~= 3840 then
        local ok = pcall(function() getCore():setResolutionAndFullScreen(3840, 2160, true) end)
        S.say("fullscreen 3840x2160 asked " .. tostring(ok) .. " (was " .. sw .. "x" .. sh .. ")")
    end
    -- Angel by name: "Angel Cross" over his head (the server shows first and last names and not the user name,
    -- cinema_angel_close.ps1 -Set)
    pcall(function() local d = p:getDescriptor(); d:setForename("Angel"); d:setSurname("Cross") end)
    pcall(function() p:setDisplayName("Angel Cross") end)
    -- no red "admin" tag: the admin powers all off (the game's Admin Powers window: none ticked, no tag), sent as it sends them
    for _, f in ipairs({ "setGodMod", "setInvisible", "setNoClip", "setFastMoveCheat", "setTimedActionInstantCheat", "setUnlimitedCarry",
                         "setUnlimitedEndurance", "setUnlimitedAmmo", "setKnowAllRecipes", "setBuildCheat", "setFarmingCheat", "setFishingCheat",
                         "setHealthCheat", "setMechanicsCheat", "setMovablesCheat", "setCanSeeAll", "setCanHearAll", "setZombiesDontAttack",
                         "setCanUseBrushTool", "setCanUseLootZed", "setCanUseLootLog", "setAnimalCheat", "setAnimalExtraValuesCheat", "setAlwaysDayCheat" }) do
        pcall(function() p[f](p, false) end)
    end
    pcall(function() sendPlayerExtraInfo(p) end)
    -- the admin's inventory trimmed for the picture (355 things and a Heavy Load moodle on the first take): everything
    -- not worn or in hand taken out of the main inventory (this client's copy; the server's database is put back after)
    local inv, n = p:getInventory(), 0
    pcall(function()
        local items, rm = inv:getItems(), {}
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local keep = it == p:getPrimaryHandItem() or it == p:getSecondaryHandItem()
            pcall(function() keep = keep or p:isEquipped(it) end)
            pcall(function() keep = keep or p:isEquippedClothing(it) end)
            pcall(function() keep = keep or p:getWornItems():contains(it) end)
            if not keep then rm[#rm + 1] = it end
        end
        for _, it in ipairs(rm) do inv:Remove(it); n = n + 1 end
    end)
    S.say(string.format("Angel %s %s | inventory: %d taken out, %.1f kg left", tostring(p:getDescriptor():getForename()), tostring(p:getDescriptor():getSurname()), n, inv:getCapacityWeight()))
end)
-- night: the server's own clock set (the shim's ZeDQA.time, QARole.lua), and the client's held at night every frame for
-- the picture; the admin's time controls (top right) hidden while it is held
S.step(5, function()
    pcall(function() sendClientCommand(p, "ZeDQA", "time", { h = 23.5 }) end)
    A.night = function()
        pcall(function() getGameTime():setTimeOfDay(23.5) end)
        pcall(function() UIManager.getSpeedControls():setVisible(false) end)
    end
    Events.OnTick.Add(A.night)
    -- (the controls' own update shows them again each frame, so setVisible did not hold on the second take: they are
    -- taken out of the UI list for the picture and put back after)
    pcall(function() UIManager.RemoveElement(UIManager.getSpeedControls()); A.speedOut = true end)
    -- fed, watered and healed (god mode is off for the tag: hunger, thirst and pain moodles stood at the edge), here
    -- and on the server (the shim's ZeDQA.fresh)
    pcall(function() sendClientCommand(p, "ZeDQA", "fresh", {}) end)
    pcall(function() p:getBodyDamage():RestoreToFullHealth() end)
    for _, k in ipairs({ "HUNGER", "THIRST", "FATIGUE", "PAIN", "STRESS", "BOREDOM", "UNHAPPINESS", "PANIC" }) do
        pcall(function() p:getStats():set(CharacterStat[k], 0) end)
    end
    pcall(function() p:getStats():set(CharacterStat.ENDURANCE, 1) end)
    C.clearSky()
    p:setDir(IsoDirections.S)
end)
S.step(300, function()
    S.say(string.format("screen %dx%d | time %.2f", getCore():getScreenWidth(), getCore():getScreenHeight(), getGameTime():getTimeOfDay()))
end)
-- a warm light where they stand (night is black: as gallery_cinema_mckline.lua's emergency light), taken away after
S.step(30, function()
    A.lights = {}
    pcall(function() A.lights[#A.lights + 1] = getCell():addLamppost(math.floor(p:getX()), math.floor(p:getY()) + 1, 0, 1.0, 0.8, 0.55, 9) end)
end)
-- the others: within 4 squares, at least CANG_GUESTS of them (cinema_angel_close.ps1 sets it), up to 3 minutes
local function others()
    local out = {}
    pcall(function()
        local l = getOnlinePlayers()
        for i = 0, l:size() - 1 do
            local o = l:get(i)
            if o ~= p and math.abs(o:getX() - p:getX()) <= 4 and math.abs(o:getY() - p:getY()) <= 4 then out[#out + 1] = o end
        end
    end)
    return out
end
S.poll(30, 360, function()
    local n = #others()
    return n >= (CANG_GUESTS or 3)
end)
S.step(5, function()
    local names = {}
    for _, o in ipairs(others()) do names[#names + 1] = tostring(o:getUsername()) .. string.format("@%.0f,%.0f", o:getX(), o:getY()) end
    S.say("players beside Angel: " .. #names .. " (" .. table.concat(names, ", ") .. ")")
end)
C.lookAround(S, "S")
S.step(5, function() p:setDir(IsoDirections.S) end)
C.pointerAway(S)
C.zoom(S, 0.75)
S.step(30, function() C.windows("loot", "loot") end)
S.step(30, function()
    local ok = pcall(function() ZeD_CharacterWindow.openTab(pn, "server") end)
    S.say("server tab " .. tostring(ok) .. " -> " .. tostring(ZeD_CharacterWindow.getWindow()._activeTab))
end)
S.step(30, function() C.worldTab("loot") end)
S.step(120, function() p:setDir(IsoDirections.S) end)
A.ml = function(k) local v = "?"; pcall(function() v = tostring(p:getMoodles():getMoodleLevel(MoodleType[k])) end); return v end
C.whenStill(S, function()
    local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    S.say(string.format("tabs %s / %s | time %.2f | players beside %d | scale %s | time controls out %s | moodles hunger %s thirst %s", tostring(c._activeTab), tostring(w._activeTab), getGameTime():getTimeOfDay(), #others(), tostring(Sc and Sc.root and Sc.root()), tostring(A.speedOut), A.ml("Hungry"), A.ml("Thirst")))
    C.boxes(S, "ang_close")
    C.shot(S, "ang_close")
end)
S.step(20, function()
    if A.night then Events.OnTick.Remove(A.night) end
    if A.speedOut then pcall(function() UIManager.AddUI(UIManager.getSpeedControls()) end) end
    pcall(function() UIManager.getSpeedControls():setVisible(true) end)
    for _, l in ipairs(A.lights or {}) do pcall(function() getCell():removeLamppost(l) end) end
    C.noWindows()
    if A.scaled then Sc.override = A.scaleWas; Sc.refresh(); ZeD.applyTheme() end
    S.say("DONE")
end)
S.run()
