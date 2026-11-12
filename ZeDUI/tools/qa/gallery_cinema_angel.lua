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
        ST.tpSq(P.clerk)
        A.face = DIRN[tostring(P.queueDir[1]) .. "," .. tostring(P.queueDir[2])] or "E"
        S.say(string.format("behind the counter at %d,%d facing %s (counter %d,%d)", P.clerk[1], P.clerk[2], A.face, P.counter[1], P.counter[2]))
    end)
    C.lookAround(S, "S")
    S.step(5, function() p:setDir(IsoDirections[A.face or "E"]) end)
    C.pointerAway(S)
    C.zoom(S, 0.75)
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
        S.say(string.format("columns: char %d world %d | tabs %s / %s | time %.2f", #(c._mcSelected or {}), #(w._mcSelected or {}), tostring(c._activeTab), tostring(w._activeTab), getGameTime():getTimeOfDay()))
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
    pcall(function() SendCommandToServer('/godmod "' .. p:getUsername() .. '" -true') end)
end)
-- night: the server sets the clock; the client's own clock is held at night every frame for the picture
S.step(5, function()
    A.night = function() pcall(function() getGameTime():setTimeOfDay(23.0) end) end
    Events.OnTick.Add(A.night)
    C.clearSky()
    p:setDir(IsoDirections.S)
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
C.whenStill(S, function()
    local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    S.say(string.format("tabs %s / %s | time %.2f | players beside %d | scale %s", tostring(c._activeTab), tostring(w._activeTab), getGameTime():getTimeOfDay(), #others(), tostring(Sc and Sc.root and Sc.root())))
    C.boxes(S, "ang_close")
    C.shot(S, "ang_close")
end)
S.step(20, function()
    if A.night then Events.OnTick.Remove(A.night) end
    for _, l in ipairs(A.lights or {}) do pcall(function() getCell():removeLamppost(l) end) end
    C.noWindows()
    if A.scaled then Sc.override = A.scaleWas; Sc.refresh(); ZeD.applyTheme() end
    S.say("DONE")
end)
S.run()
