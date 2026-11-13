-- ZeDUI/tools/qa/known_issues_sim.lua  (Nov 7 2026, Build): the beta 7 known issues, with no game running. The real files
-- run on Lua 5.1 stubs of the game. (ZeD picks on the Mods screen: mods_order_sim.lua; the dashes per player and the
-- ash tray's client side: dash_odo_sim.lua, SPLIT and SERVER.)
--   ASH     the server's side of the ash tray (ZeD_ServerDash.lua, DP.ASH): a press from anyone in the car; the
--           server writes ZeD_ash on its own copy of the car and sends the car out; junk is logged, a player not in the
--           car or pressing too fast is refused, a tray already so is not sent again; the odometer's handlers still there
--   SPLIT   split-screen: ZeD's Character and World windows answer the first player only (the others get the game's
--           own, through every way in, the pad's Y and D-pad included); each local player has a belt of their own,
--           placed and hidden on its own, a drop and the pad's leaving going to the right one; the server link sends
--           as the player it is handed
--   S0      split-screen's groundwork, the first player unchanged: ZeD.playerRect gives each player their part of the
--           screen (a two-player split stubbed), the whole screen when the game cannot answer; ZeD.screenOf (what the
--           windows fit, open, drag and slide on) is still the whole screen for everyone; the windows are kept one a
--           player, getWindow() is getWindow(0), closing one player's leaves the other's; the gate is as it was
--   S1      split-screen's input per player, the first player unchanged: two local players on two pads (the real
--           Input files, QuickChords and the joypad stubs on a stubbed engine); the second pad never moves the first
--           player's focus, holds, chord or input mode; the first player's run is the run before S1, line for line
--           (GOLDEN, taken from the files as they were); with the gate opened for player 2 in the sim only, player 2
--           gets focus, holds, repeat and chord of their own; joining, dying, a pad unplugged mid-hold, a pad in
--           character creation. (Organisms.lua's own five stubs still gate on player 1's window; the opened-gate
--           games give their copy the dash's gate, the change held for split-screen's windows stage.)
--           ZEDQA_S1_DUMP=1 prints the first player's run as it is now.
--   MONTHS  the French and Hungarian month words are lower case in dates (Journal and main menu keys); English keeps
--           its capitals
-- Run from the repo root:  lua51 ZeDUI/tools/qa/known_issues_sim.lua
-- It prints FAIL lines and a last line "known_issues_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]known_issues_sim%.lua$", "")
local LUA = ROOT .. "42/media/lua/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function readFile(path)
    local h = io.open(path, "rb")
    if not h then return nil end
    local s = h:read("*a")
    h:close()
    return s
end

-- events as the game keeps them: each Add written down, so a test can fire one
local EV = {}
Events = setmetatable({}, { __index = function(t, k)
    local e = { fns = {} }
    e.Add = function(fn) e.fns[#e.fns + 1] = fn end
    e.Remove = noop
    rawset(t, k, e)
    EV[k] = e
    return e
end })
local function fire(name, ...) for _, fn in ipairs(Events[name].fns) do fn(...) end end
require = noop
local clock = 100000
getTimestampMs = function() return clock end

-- ---------------------------------------------------------------------------
section("ASH")
-- ---------------------------------------------------------------------------
do
    isServer = function() return true end
    ZeD = {}
    dofile(LUA .. "shared/ZeD/ZeD_DashProto.lua")
    local DP = ZeD.DashProto
    local handlers, bad, last = {}, {}, {}
    ZeD.Srv = {
        modules = {},
        register = function(module, command, opts, fn) handlers[module .. "." .. command] = fn end,
        bad = function(p, what) bad[#bad + 1] = what end,
        left = function(p, key, ms)
            local at = last[p.name .. key]
            if at and clock - at < ms then return 1 end
            return nil
        end,
        mark = function(p, key) last[p.name .. key] = clock end,
        to = noop,
    }
    local cars = {}
    getVehicleById = function(id) return cars[id] end
    local function newCar(id)
        local c = { id = id, md = {}, tx = 0 }
        c.getModData = function(self) return self.md end
        c.transmitModData = function(self) self.tx = self.tx + 1 end
        c.getDriver = function() return nil end
        cars[id] = c
        return c
    end
    local function player(name, car)
        return { name = name, getUsername = function() return name end, getVehicle = function() return car end }
    end
    dofile(LUA .. "server/ZeD/ZeD_ServerDash.lua")
    local ash = handlers[DP.MOD .. "." .. tostring(DP.ASH)]
    check("the server takes the ash tray command", DP.ASH ~= nil and type(ash) == "function")
    check("the odometer's commands are still there", type(handlers[DP.MOD .. "." .. DP.ODO]) == "function"
        and type(handlers[DP.MOD .. "." .. DP.ASK]) == "function")
    if type(ash) == "function" then
        local car = newCar(12)
        local rider = player("rider", car)
        ash(rider, { veh = 12, open = true })
        check("a press from inside the car: the server's copy keeps it", car.md.ZeD_ash == true, tostring(car.md.ZeD_ash))
        check("and the car goes out to the clients near it", car.tx == 1, car.tx)
        ash(rider, { veh = 12, open = false })
        check("a second press at once is refused", car.md.ZeD_ash == true and car.tx == 1)
        clock = clock + DP.ASH_MS
        ash(rider, { veh = 12, open = false })
        check("a press after a moment is taken", car.md.ZeD_ash == false and car.tx == 2, car.tx)
        clock = clock + DP.ASH_MS
        ash(rider, { veh = 12, open = false })
        check("a tray already so is not sent again", car.tx == 2, car.tx)
        clock = clock + DP.ASH_MS
        local outside = player("walker", nil)
        ash(outside, { veh = 12, open = true })
        check("a player not in the car is refused", car.md.ZeD_ash == false and car.tx == 2)
        local other = newCar(13)
        clock = clock + DP.ASH_MS
        ash(player("elsewhere", other), { veh = 12, open = true })
        check("a player in another car is refused", car.md.ZeD_ash == false)
        local nBad = #bad
        clock = clock + DP.ASH_MS
        ash(rider, { veh = 12, open = "yes" })
        ash(rider, { veh = 1.5, open = true })
        ash(rider, { veh = 12 })
        ash(rider, "junk")
        check("junk is logged and changes nothing", #bad == nBad + 4 and car.md.ZeD_ash == false, #bad - nBad)
        clock = clock + DP.ASH_MS
        ash(rider, { veh = 999, open = true })
        check("no such car: nothing", car.md.ZeD_ash == false and #bad == nBad + 4)
        -- the other keys on the server's copy stay (it writes only its own)
        car.md.Roadworthy = { odo = 3 }
        clock = clock + DP.ASH_MS
        ash(rider, { veh = 12, open = true })
        check("another mod's key on the car stays", car.md.Roadworthy and car.md.Roadworthy.odo == 3 and car.md.ZeD_ash == true)
    end
    check("the shape test takes a press and refuses junk", DP.okAsh and DP.okAsh({ veh = 3, open = false })
        and not DP.okAsh({ veh = 3 }) and not DP.okAsh({ veh = "3", open = true }) and not DP.okAsh(nil))
end

-- ---------------------------------------------------------------------------
section("SPLIT")
-- ---------------------------------------------------------------------------
do
    -- the gate every way into ZeD's windows asks (Atoms.lua is big: the one function is read out of it)
    local atoms = readFile(LUA .. "client/ZeD/Atoms.lua") or ""
    local fnSrc = atoms:match("(function ZeD%.windowsFor%(pn%).-\nend)")
    check("ZeD.windowsFor is in Atoms.lua", fnSrc ~= nil)
    ZeD = {}
    if fnSrc then assert(loadstring(fnSrc))() end
    local W = ZeD.windowsFor
    check("the first player has ZeD's windows", W and W(0) and W(nil))
    check("the others have the game's own", W and not W(1) and not W(2) and not W(3))

    -- every way in asks it (read from the sources: the windows need the whole game to load)
    local function count(file, pat)
        local s = readFile(LUA .. "client/ZeD/" .. file) or ""
        local _, n = s:gsub(pat, "")
        return n
    end
    local function gated(file, fnName)
        local s = readFile(LUA .. "client/ZeD/" .. file) or ""
        s = s:gsub("\r\n", "\n")
        local body = s:match("\nfunction " .. fnName:gsub("%.", "%%.") .. "%b()(.-)\nend\n")
        return body ~= nil and body:sub(1, 400):find("ZeD.windowsFor(", 1, true) ~= nil
    end
    for _, w in ipairs({
        { "ZeD_CharacterWindow.lua", "ZeD_CharacterWindow.toggle" },
        { "ZeD_CharacterWindow.lua", "ZeD_CharacterWindow.openTab" },
        { "ZeD_CharacterWindow.lua", "ZeD_CharacterWindow.toggleBothPaired" },
        { "ZeD_CharacterWindow.lua", "ZeD_CharacterWindow.ensureBothOpenForGamepad" },
        { "Overrides/CharacterInfo.lua", "ZeD_CharacterWindow.openTab" },
        { "ZeD_WorldWindow.lua", "ZeD_WorldWindow.toggle" },
        { "ZeD_WorldWindow.lua", "ZeD_WorldWindow.open" },
        { "ZeD_WorldWindow.lua", "ZeD_WorldWindow.openTab" },
        { "ZeD_WorldWindow.lua", "ZeD_WorldWindow.openObjectCard" },
    }) do
        check("only the first player's press opens ZeD's: " .. w[2] .. " (" .. w[1] .. ")", gated(w[1], w[2]))
    end
    check("the pad's Y: the game's inventory for the other players",
        count("ZeD_CharacterWindow.lua", "not ZeD%.windowsFor%(self%.player%)%) then return _vanillaOnYPress%(self%)") == 1)
    check("another player's D-pad never moves the first player's window",
        count("ZeD_DpadWheels.lua", "if not ZeD%.windowsFor%(joypadData and joypadData%.player or 0%) then return false end") == 1)
    check("another player's D-pad and Select: the game's own wheels",
        count("ZeD_DpadWheels.lua", "if D%.gameWheels%(%) or not ZeD%.windowsFor%(joypadData and joypadData%.player or 0%) then return orig%(joypadData%) end") == 1
        and count("ZeD_DpadWheels.lua", "if D%.gameWheels%(%) or not ZeD%.windowsFor%(self%.playerNum or 0%) then") == 1)
    check("another player's map: the game's own (show, hide, toggle)",
        count("Overrides/WorldMap.lua", "ZeD%.windowsFor%(playerNum") == 3)
    for _, w in ipairs({
        { "Overrides/Wheels.lua", "local function openPair" },
        { "Overrides/Garment.lua", "local function openCard" },
        { "ZeD_DpadWheels.lua", "function H.charTab" },
        { "ZeD_DpadWheels.lua", "function H.worldTab" },
        { "ZeD_QuickWheel.lua", "local function treat" },
        { "ModSupport/SPNCC.lua", "function S.openTab" },
    }) do
        local s = (readFile(LUA .. "client/ZeD/" .. w[1]) or ""):gsub("\r\n", "\n")
        local at = s:find(w[2], 1, true)
        check("asks first: " .. w[2] .. " (" .. w[1] .. ")", at ~= nil and s:sub(at, at + 300):find("ZeD.windowsFor(", 1, true) ~= nil)
    end
    check("both windows know their player", count("ZeD_CharacterWindow.lua", "win%.playerNum = playerNum") == 1
        and count("ZeD_WorldWindow.lua", "win%.playerNum = playerNum") == 1)

    -- the belt, one a player: the real ZeD_Belt.lua on stubs
    ZeD = { Safe = { on = function() return false end }, tr = function(k) return k end, trDefaults = noop }
    local Panel = {}
    Panel.__index = Panel
    function Panel:derive() local c = {}; c.__index = c; return setmetatable(c, { __index = Panel }) end
    function Panel:new() return { _vis = false } end
    function Panel:initialise() end
    function Panel:addToUIManager() self._inUI = true end
    function Panel:setVisible(v) self._vis = v end
    function Panel:getIsVisible() return self._vis end
    function Panel:getMouseX() return self._mx or -1 end
    function Panel:getMouseY() return self._my or -1 end
    function Panel:getWidth() return 100 end
    function Panel:getHeight() return 20 end
    ZeD_Panel = Panel
    ZeD_BeltHUD = nil
    local inCar = {}
    local players = {}
    for pn = 0, 1 do
        players[pn] = { isDead = function() return false end, getVehicle = function() return inCar[pn] end,
            setJoypadIgnoreAimUntilCentered = noop }
    end
    getSpecificPlayer = function(pn) return players[pn] end
    getCore = function() return { getGameMode = function() return "Sandbox" end } end
    getPlayerHotbar = function(pn) return players[pn] and {} or nil end
    local focusSet = {}
    setJoypadFocus = function(pn, w) focusSet[#focusSet + 1] = { pn = pn, w = w } end
    local reclaimed = 0
    ZeD.Input = { Focus = { getFocusedWindow = function() return { isVisible = function() return true end } end,
        reclaimEngineFocus = function() reclaimed = reclaimed + 1 end } }
    ISUIHandler = nil
    local ok, err = pcall(dofile, LUA .. "client/ZeD/ZeD_Belt.lua")
    check("the belt file loads", ok, err)
    local B = ZeD.Belt
    if ok and B then
        B.hotbar = function(pn) return getPlayerHotbar(pn) end
        fire("OnGameStart")
        local b0 = B.getHUD and B.getHUD(0)
        check("the first player's belt at the game's start", b0 ~= nil and b0.playerNum == 0 and B._hud == b0)
        fire("OnCreatePlayer", 1)
        local b1 = B.getHUD(1)
        check("a second player gets a belt of their own", b1 ~= nil and b1 ~= b0 and b1.playerNum == 1, tostring(b1))
        check("in the UI", b1 ~= nil and b1._inUI == true)
        fire("OnCreatePlayer", 1)
        check("a respawn keeps the one there is", B.getHUD(1) == b1)
        check("no argument: the first player's belt (the callers that know of one)", B.getHUD() == b0)
        -- each shown or hidden on its own: the second player in a car, the first on foot
        inCar[1] = {}
        fire("OnTick")
        check("the second player in a car: their belt hides", b1 and not b1:getIsVisible())
        check("the first player's stays", b0 and b0:getIsVisible())
        -- a drop goes to the belt of the player who dropped it
        if b1 and b0 then
            b1._drawn, b0._drawn = true, true
            b1._mx, b1._my = -1, -1
            b0._mx, b0._my = 5, 5
            b0.boxAt = function() return nil end
            local asked1 = false
            b1.boxAt = function() asked1 = true; return nil end
            B.takeDrop(1, { {} })
            check("a drop is offered to the dropping player's belt", not asked1 and b0._mx == 5)
            b1._mx, b1._my = 5, 5
            B.takeDrop(1, { {} })
            check("over the second player's belt: theirs is asked", asked1)
        end
        -- leaving the pad on the second player's belt never pulls the first player's window back
        if b1 and b1._leavePad then
            local r0 = reclaimed
            b1._gp = {}
            b1:_leavePad()
            check("the second player's belt lets their pad go to their game", reclaimed == r0 and focusSet[#focusSet].pn == 1)
            b0._gp = {}
            b0:_leavePad()
            check("the first player's goes back to their window, as before", reclaimed == r0 + 1)
        end
    end

    -- the server link sends as the player it is handed (the game sends that player's index with the command)
    ZeD = { Tk = { MOD_LINK = "ZeDLink", PROTO = 1 } }
    local sentBy = {}
    isClient = function() return true end
    local first = { isLocalPlayer = function() return true end, n = 0 }
    local second = { isLocalPlayer = function() return true end, n = 1 }
    local remote = { isLocalPlayer = function() return false end, n = 9 }
    getPlayer = function() return first end
    sendClientCommand = function(p, module, command, args) sentBy[#sentBy + 1] = p end
    local okL, errL = pcall(dofile, LUA .. "client/ZeD/ZeD_ServerLink.lua")
    check("the server link loads", okL, errL)
    local S = ZeD.ServerPart
    if okL and S then
        S.send("m", "c", {}, second)
        S.send("m", "c", {})
        S.send("m", "c", {}, remote)
        check("sent as the player handed", sentBy[1] == second, sentBy[1] and sentBy[1].n)
        check("none handed: the first player, as before", sentBy[2] == first)
        check("never as a player who is not on this machine", sentBy[3] == first)
    end
end

-- ---------------------------------------------------------------------------
section("S0")
-- ---------------------------------------------------------------------------
do
    -- the files' own functions, cut out by name (the windows need the whole game to load)
    local function src(file) return ((readFile(LUA .. "client/ZeD/" .. file) or ""):gsub("\r\n", "\n")) end
    local function fnOf(s, head)   -- from "\n<head>(" to the function's own "end" at the start of a line
        local a = s:find("\n" .. head .. "(", 1, true)
        if not a then return nil end
        local b = s:find("\nend\n", a + 1, true)
        return b and s:sub(a + 1, b + 4) or nil
    end
    local atoms, orgs = src("Atoms.lua"), src("Organisms.lua")
    local cw, ww = src("ZeD_CharacterWindow.lua"), src("ZeD_WorldWindow.lua")

    -- a two-player split: the screen cut down the middle, the first player on the left
    local SW, SH = 1920, 1080
    getCore = function() return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end } end
    local RECTS = { [0] = { 0, 0, 960, 1080 }, [1] = { 960, 0, 960, 1080 } }
    local function part(i) return function(pn) local r = RECTS[pn]; return r and r[i] or 0 end end
    getPlayerScreenLeft, getPlayerScreenTop = part(1), part(2)
    getPlayerScreenWidth, getPlayerScreenHeight = part(3), part(4)

    ZeD = {}
    local prSrc = fnOf(atoms, "function ZeD.playerRect")
    check("ZeD.playerRect is in Atoms.lua", prSrc ~= nil)
    if prSrc then assert(loadstring(prSrc))() end
    local function rect(pn) return table.concat({ ZeD.playerRect(pn) }, ",") end
    if ZeD.playerRect then
        check("the first player's part: the left half", rect(0) == "0,0,960,1080", rect(0))
        check("the second player's part: the right half", rect(1) == "960,0,960,1080", rect(1))
        check("no player named: the first player's", rect(nil) == rect(0), rect(nil))
        check("a player with no part (none there): the whole screen", rect(2) == "0,0,1920,1080", rect(2))
        RECTS = { [0] = { 0, 0, 1920, 1080 } }
        check("one player: the whole screen", rect(0) == "0,0,1920,1080", rect(0))
        local keepW = getPlayerScreenWidth
        getPlayerScreenWidth = function() error("the Java side threw") end
        check("the game throwing: the whole screen", rect(1) == "0,0,1920,1080", rect(1))
        getPlayerScreenWidth = nil
        check("no such function (another build): the whole screen", rect(0) == "0,0,1920,1080", rect(0))
        getPlayerScreenWidth = keepW
        RECTS = { [0] = { 0, 0, 960, 1080 }, [1] = { 960, 0, 960, 1080 } }
    end

    -- what the windows fit, open, drag and slide on: the whole screen for everyone, as before (split-screen windows
    -- switch it to their player's part later)
    local soSrc = fnOf(orgs, "function ZeD.screenOf")
    check("ZeD.screenOf is in Organisms.lua", soSrc ~= nil)
    if soSrc then assert(loadstring(soSrc))() end
    local function scr(w) return table.concat({ ZeD.screenOf(w) }, ",") end
    if ZeD.screenOf then
        check("the first player's windows: the whole screen, as before", scr(0) == "1920,1080,0,0" and scr({ playerNum = 0 }) == "1920,1080,0,0", scr(0))
        check("for now the second player's too (their windows do not open yet)", scr(1) == "1920,1080,0,0" and scr({ playerNum = 1 }) == "1920,1080,0,0", scr(1))
    end
    -- every screen size the window code reads comes through it (the pair, the reset, the saved places, the roll)
    local direct = {}
    for _, f in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua", "ZeD_WindowPlaces.lua", "WindowCurtain.lua", "WindowHalves.lua" }) do
        if src(f):find("getCore():getScreen", 1, true) then direct[#direct + 1] = f end
    end
    local resetSrc = fnOf(orgs, "function ZeD_Window.resetLayout") or ""
    local stepSrc = fnOf(orgs, "function ZeD_Window:_resizeStep") or ""
    if (resetSrc .. stepSrc):find("getCore():getScreen", 1, true) or resetSrc == "" or stepSrc == "" then direct[#direct + 1] = "Organisms.lua" end
    check("the window code reads the screen only through ZeD.screenOf", #direct == 0, table.concat(direct, " "))

    -- the windows, one a player: the Character window's lookups on a map holding two players' windows
    check("the Character windows are a map", cw:find("\nlocal _charWins = {}\n", 1, true) ~= nil and not cw:find("_charWin[^%w_]"))
    check("the World windows are a map", ww:find("\nlocal _worldWins = {}\n", 1, true) ~= nil and not ww:find("_worldWin[^%w_]"))
    local w0 = { playerNum = 0 }
    local w1 = { playerNum = 1 }
    local cwFns = ""
    for _, n in ipairs({ "getInstance", "isOpen", "getWindow" }) do cwFns = cwFns .. (fnOf(cw, "function ZeD_CharacterWindow." .. n) or "") .. "\n" end
    local cwChunk = loadstring("local _charWins = ...\nlocal ZeD_CharacterWindow = {}\n" .. cwFns .. "return ZeD_CharacterWindow")
    check("the Character window's lookups load", cwChunk ~= nil)
    if cwChunk then
        local C = cwChunk({ [0] = w0, [1] = w1 })
        check("Character: getWindow() is getWindow(0), the first player's", C.getWindow and C.getWindow() == w0 and C.getWindow(0) == w0)
        check("Character: getInstance() too", C.getInstance and C.getInstance() == w0 and C.getInstance(1) == w1)
        check("Character: the second player's by number", C.getWindow and C.getWindow(1) == w1)
        check("Character: isOpen per player", C.isOpen and C.isOpen() and C.isOpen(1) and not C.isOpen(2))
    end
    -- the World window's, and its close: closing one player's window leaves the other's
    local saved = {}
    local wwFns = (fnOf(ww, "local function _closeWorldWindow") or "") .. "\n"
    for _, n in ipairs({ "isOpen", "getWindow", "getObjectCard", "close" }) do wwFns = wwFns .. (fnOf(ww, "function ZeD_WorldWindow." .. n) or "") .. "\n" end
    local wwChunk = loadstring("local _worldWins, saveWorldState = ...\nlocal _floorContainer = {}\n"
        .. "ZeD_WorldWindow = { _endZoneDraw = function() end }\n" .. wwFns .. "return ZeD_WorldWindow")
    check("the World window's lookups load", wwChunk ~= nil)
    if wwChunk then
        local function mk(pn)
            return { playerNum = pn, _drawerObject = {}, _objectCard = "card" .. pn,
                     removeFromUIManager = function(self) self.removed = true end }
        end
        local v0, v1 = mk(0), mk(1)
        local map = { [0] = v0, [1] = v1 }
        local Wm = wwChunk(map, function(w) saved[#saved + 1] = w end)
        check("World: getWindow() is getWindow(0), the first player's", Wm.getWindow() == v0 and Wm.getWindow(0) == v0 and Wm.getWindow(1) == v1)
        check("World: the object card per player", Wm.getObjectCard() == "card0" and Wm.getObjectCard(1) == "card1")
        check("World: isOpen per player", Wm.isOpen() and Wm.isOpen(1) and not Wm.isOpen(3))
        Wm.close(1)
        check("World: closing the second player's window leaves the first player's", v1.removed and map[1] == nil and map[0] == v0 and not v0.removed)
        check("World: and saves the one it closed", saved[1] == v1)
        Wm.close()
        check("World: close() closes the first player's, as before", v0.removed and map[0] == nil and saved[2] == v0)
    end
    -- a window opened for a player lands in that player's place in the map, and its own close clears only that place
    -- (toggle needs the whole game; its lines are read from the source)
    local cwToggle = fnOf(cw, "function ZeD_CharacterWindow.toggle") or ""
    local wwToggle = fnOf(ww, "function ZeD_WorldWindow.toggle") or ""
    check("Character: a new window is kept under its player's number", cwToggle:find("_charWins[playerNum] = win", 1, true) ~= nil)
    check("Character: its close box clears only its own player's", cwToggle:find("_charWins[self.playerNum or 0] = nil", 1, true) ~= nil)
    check("World: a new window is kept under its player's number", wwToggle:find("_worldWins[playerNum] = win", 1, true) ~= nil)
    check("both open where the screen they live on says (ZeD.screenOf by the player's number)",
        cwToggle:find("ZeD.screenOf(playerNum)", 1, true) ~= nil and wwToggle:find("ZeD.screenOf(playerNum)", 1, true) ~= nil)

    -- the gate, word for word as it was: only the first player opens ZeD's windows
    local gate = fnOf(atoms, "function ZeD.windowsFor")
    check("the gate is unchanged", gate == "function ZeD.windowsFor(pn)\n    return pn == nil or pn == 0\nend\n", gate)
end

-- ---------------------------------------------------------------------------
section("S1")
-- ---------------------------------------------------------------------------
do
    local function src(file) return ((readFile(LUA .. "client/ZeD/" .. file) or ""):gsub("\r\n", "\n")) end
    local function fnOf(s, head)   -- from "\n<head>(" to the function's own "end" at the start of a line
        local a = s:find("\n" .. head .. "(", 1, true)
        if not a then return nil end
        local b = s:find("\nend\n", a + 1, true)
        return b and s:sub(a + 1, b + 4) or nil
    end
    -- every global a game below sets, put back when the section ends
    local GLOBALS = { "Events", "print", "ZeD", "Joypad", "JoypadButton", "Keyboard", "JoypadState", "getJoypadData",
        "getJoypadFocus", "setJoypadFocus", "setJoypadIgnoreAimUntilCentered", "getSpecificPlayer", "getCore",
        "getGameSpeed", "isDebugEnabled", "getMouseX", "getMouseY", "isMouseButtonDown", "getSoundManager", "UIManager",
        "LuaEventManager", "triggerEvent", "getControllerCount", "isControllerConnected", "getControllerAxisValue",
        "getControllerName", "ZeD_CharacterWindow", "ZeD_WorldWindow", "JoypadControllerData", "ZeD_Window",
        "ZeD_Panel", "CoopCharacterCreation", "getTimestampMs", "getMaxActivePlayers" }
    local saved = {}
    for _, k in ipairs(GLOBALS) do saved[k] = _G[k] end
    local realPrint = print

    local orgs, panelSrc, atoms = src("Organisms.lua"), src("ZeD_Panel.lua"), src("Atoms.lua")
    local FILES = { "Input/ActionMap.lua", "Input/BumperChord.lua", "Input/FocusManager.lua",
        "Input/InputModeDetector.lua", "Input/SpatialNav.lua", "ZeD_QuickChords.lua" }
    local CODE = {}
    for _, f in ipairs(FILES) do CODE[f] = src(f) end
    local STUBS = {}
    for _, d in ipairs({ "Down", "DirUp", "DirDown", "DirLeft", "DirRight" }) do
        STUBS[#STUBS + 1] = fnOf(orgs, "function ZeD_Window:onJoypad" .. d) or ""
        STUBS[#STUBS + 1] = fnOf(panelSrc, "function ZeD_Panel:onJoypad" .. d) or ""
    end
    check("S1 harness: the ten joypad stubs cut from Organisms.lua and ZeD_Panel.lua", #table.concat(STUBS) > 500)
    local gateSrc = fnOf(atoms, "function ZeD.windowsFor")
    local BUTTONS = { "A", "B", "X", "Y", "LeftBump", "RightBump", "Back", "Start", "LeftStick", "RightStick",
        "DPadUp", "DPadDown", "DPadLeft", "DPadRight" }
    local ANY = { A = true, B = true, X = true, Y = true, Back = true, Start = true, LeftStick = true, RightStick = true }
    local DIR = { up = "DPadUp", down = "DPadDown", left = "DPadLeft", right = "DPadRight" }
    local DIRFN = { up = "onJoypadDirUp", down = "onJoypadDirDown", left = "onJoypadDirLeft", right = "onJoypadDirRight" }
    local MENU = { _zedLabel = "menu" }
    local function lab(w) return w and (w._zedLabel or "?") or "nil" end

    -- one game, fresh each time: the real files loaded in the game's order on stubs of the engine; W carries the
    -- helpers and the transcript ("<ms> p<player> <what>", ms counted from the start of this game)
    local function world(opts)
        opts = opts or {}
        local W = { T = {}, t0 = clock, mx = 500, my = 500, mouse = false }
        local T = W.T
        local function rec(pn, text) T[#T + 1] = string.format("%5d p%s %s", clock - W.t0, tostring(pn), text) end
        W.rec = rec
        Events = setmetatable({}, { __index = function(t, k)
            local e = { fns = {} }
            e.Add = function(fn) e.fns[#e.fns + 1] = fn end
            e.Remove = noop
            rawset(t, k, e)
            return e
        end })
        local function fireE(name, ...) for _, fn in ipairs(Events[name].fns) do fn(...) end end
        W.fire = fireE
        print = function(...)
            local parts = {}
            for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
            local s = table.concat(parts, " ")
            if s:sub(1, 5) == "[ZeD." or s:sub(1, 5) == "[ZeD]" then
                local n = s:match("%(player (%d)%)$")
                rec(n and (tonumber(n) - 1) or 0, s)
            else
                realPrint(s)
            end
        end
        LuaEventManager = { AddEvent = noop }
        triggerEvent = function(name, a, b, c)
            if name == "ZeD_FocusChanged" then rec(c or 0, "focus " .. lab(a) .. " <- " .. lab(b)) end
            fireE(name, a, b, c)
        end
        getTimestampMs = function() return clock end
        getMaxActivePlayers = function() return 4 end
        local BTN, CONN, AX = {}, {}, {}
        for i = 0, 3 do BTN[i] = {}; AX[i] = {} end
        W.BTN, W.CONN, W.AX = BTN, CONN, AX
        JoypadButton = {}
        for _, n in ipairs(BUTTONS) do
            JoypadButton[n] = { name = n, isDown = function(self, id)
                if type(id) ~= "number" then rec("?", "BAD isDown " .. tostring(id)); return false end
                if id < 0 then   -- (the engine's any-pad read: the face buttons, Back, Start and the stick clicks)
                    if not ANY[n] then return false end
                    for i = 0, 3 do if CONN[i] and BTN[i][n] then return true end end
                    return false
                end
                return (CONN[id] and BTN[id][n]) and true or false   -- (a pad gone reads all up)
            end }
        end
        local J = JoypadButton
        Joypad = { AButton = J.A, BButton = J.B, XButton = J.X, YButton = J.Y, LBumper = J.LeftBump,
            RBumper = J.RightBump, Back = J.Back, Start = J.Start, LStickButton = J.LeftStick,
            RStickButton = J.RightStick, DPadUp = J.DPadUp, DPadDown = J.DPadDown, DPadLeft = J.DPadLeft,
            DPadRight = J.DPadRight }
        Keyboard = { KEY_RETURN = 28, KEY_ESCAPE = 1, KEY_UP = 200, KEY_DOWN = 208, KEY_LEFT = 203, KEY_RIGHT = 205,
            KEY_I = 23, KEY_F9 = 67 }
        getControllerCount = function() return 4 end
        isControllerConnected = function(i)
            if type(i) ~= "number" or i < 0 then rec("?", "BAD isControllerConnected " .. tostring(i)); return false end
            return CONN[i] == true
        end
        getControllerAxisValue = function(i, a)
            if type(i) ~= "number" or i < 0 then rec("?", "BAD axis " .. tostring(i)); return 0 end
            return (CONN[i] and AX[i][a]) or 0
        end
        getControllerName = function() return "Xbox Controller" end
        JoypadState = { players = {}, joypads = {}, controllers = {} }
        getJoypadData = function(pn) return JoypadState.players[pn + 1] end
        getJoypadFocus = function(pn) local jd = JoypadState.players[pn + 1]; return jd and jd.focus end
        setJoypadFocus = function(pn, w)
            if type(pn) ~= "number" then rec("?", "BAD setJoypadFocus " .. tostring(pn)); return end
            local jd = JoypadState.players[pn + 1]
            if not jd then return end
            jd.focus = w
            rec(pn, "engine focus " .. lab(w))
        end
        setJoypadIgnoreAimUntilCentered = function(pn) rec(pn, "ignore aim") end
        local PL = {}
        local function mkPlayer(pn)
            local p = { pn = pn, dead = false }
            p.isDead = function(self) return self.dead end
            p.getPlayerNum = function(self) return self.pn end
            return p
        end
        PL[0], PL[1] = mkPlayer(0), mkPlayer(1)
        W.PL, W.mkPlayer = PL, mkPlayer
        getSpecificPlayer = function(pn) return PL[pn] end
        getCore = function() return { doZoomScroll = function(_, pn, dir) rec(pn, "zoom " .. tostring(dir)) end,
            getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end } end
        getGameSpeed = function() return 1 end
        isDebugEnabled = function() return false end
        getMouseX = function() return W.mx end
        getMouseY = function() return W.my end
        isMouseButtonDown = function(b) return b == 0 and W.mouse end
        getSoundManager = function() return { playUISound = noop } end
        UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return 1 end } end }
        CoopCharacterCreation = opts.coop
        ZeD = { Safe = { on = function() return false end }, tr = function(s) return s end, DpadWheels = { state = {} } }
        if opts.gate then ZeD.windowsFor = opts.gate elseif gateSrc then assert(loadstring(gateSrc))() end
        -- the game's controllers: a press with no focus and every release go through these (QuickChords wraps them)
        JoypadControllerData = {}
        JoypadControllerData.__index = JoypadControllerData
        function JoypadControllerData:onPressButtonNoFocus(b)
            rec(self.joypad and self.joypad.player or "?", "game press " .. b.name)
        end
        function JoypadControllerData:onReleaseButton(b)
            rec(self.joypad and self.joypad.player or "?", "game release " .. b.name)
        end
        local CTL = {}
        for i = 0, 3 do CTL[i] = setmetatable({ id = i }, JoypadControllerData) end
        W.CTL = CTL
        ZeD_Window, ZeD_Panel = {}, {}
        -- (with the gate opened for player 2, the window's stubs gate on the pressing pad's player as the dash's do:
        -- Organisms.lua's own five still name nobody, a change held for split-screen's windows stage)
        for _, s in ipairs(STUBS) do
            if opts.gate then s = (s:gsub("getFocusedWindow%(%) == self", "getFocusedWindow(joypadData and joypadData.player) == self")) end
            if s ~= "" then assert(loadstring(s))() end
        end
        for _, f in ipairs(FILES) do assert(loadstring(CODE[f], "@" .. f))() end
        local F = ZeD.Input.Focus
        W.F, W.C, W.D, W.Q = F, ZeD.Input.Chord, ZeD.Input.Detector, ZeD.QuickChords
        ZeD.QuickChords.run = function(p, chord) rec(p:getPlayerNum(), "chord " .. chord) end

        -- the Character and World windows, one of each a player: two zones, rows r1-r4 and buttons b1-b2, every
        -- callback written down under the window's player
        local WINS = { char = {}, world = {} }
        W.WINS = WINS
        local function mkWin(kind, pn)
            local label = kind .. pn
            local w = setmetatable({ playerNum = pn, _zedLabel = label, windowShaded = false }, { __index = ZeD_Window })
            local x = ((kind == "char") and 0 or 450) + ((pn == 0) and 0 or 1000)
            w.getX = function() return x end
            w.getY = function() return 0 end
            w.getWidth = function() return 400 end
            w.getHeight = function() return 300 end
            w.isVisible = function() return true end
            w.setWindowShaded = function(self, b)
                self.windowShaded = b
                rec(pn, (b and "shade " or "unshade ") .. label)
            end
            w.close = function(self)
                WINS[kind][pn] = nil
                F.unregisterWindow(self)
                rec(pn, "close " .. label)
            end
            local function cb(id, name) return function() rec(pn, label .. " " .. id .. " " .. name) end end
            local rows = {}
            for i = 1, 4 do
                local id = "r" .. i
                local el = { id = id, x = 10, y = 10 + 40 * (i - 1), w = 200, h = 30, item = {},
                    onFocus = cb(id, "onFocus"), onActivate = cb(id, "onActivate"), onPaint = cb(id, "onPaint"),
                    onContextMenu = cb(id, "onContextMenu") }
                el.onHoldActivate = function(ww) rec(pn, label .. " " .. id .. " onHoldActivate"); ww._gpPaint = { n = 1 } end
                el.onCancel = function() rec(pn, label .. " " .. id .. " onCancel"); return true end
                if i <= 2 then
                    el.onHoldContext = cb(id, "onHoldContext")
                else
                    el.onHoldContextDrag = function(_, _, dir) rec(pn, label .. " " .. id .. " onHoldContextDrag " .. tostring(dir)) end
                    el.onHoldContextRelease = cb(id, "onHoldContextRelease")
                end
                rows[i] = el
            end
            local btns = {}
            for i = 1, 2 do
                local id = "b" .. i
                btns[i] = { id = id, x = 250, y = 10 + 40 * (i - 1), w = 100, h = 30,
                    onFocus = cb(id, "onFocus"), onActivate = cb(id, "onActivate") }
            end
            w._focusRing = { { zone = "list", focusable = true, elements = rows, focusedElementIdx = 1 },
                             { zone = "btns", focusable = true, elements = btns, focusedElementIdx = 1 } }
            w._focusIdx = 1
            w._focusEntryZone = "list"
            w._focusPendingEntry = true
            return w
        end
        local function open(kind, pn)   -- (as the windows' own open does: register, then claim)
            if WINS[kind][pn] then return end
            local w = mkWin(kind, pn)
            WINS[kind][pn] = w
            rec(pn, "open " .. w._zedLabel)
            F.registerWindow(w)
            F.claimFocus(w)
        end
        local function canOpen(pn)
            local p = getSpecificPlayer(pn)
            return (not F.held()) and ZeD.windowsFor(pn) and p ~= nil and not p:isDead()
        end
        ZeD_CharacterWindow = {
            getWindow = function(pn) return WINS.char[pn or 0] end,
            isOpen = function(pn) return WINS.char[pn or 0] ~= nil end,
            ensureBothOpenForGamepad = function(pn)
                pn = pn or 0
                rec(pn, "pair")
                if not canOpen(pn) then return end
                open("char", pn); open("world", pn)
            end,
            toggleBothPaired = function(pn)
                pn = pn or 0
                rec(pn, "toggle pair")
                if canOpen(pn) then open("char", pn); open("world", pn) end
            end,
        }
        ZeD_WorldWindow = {
            getWindow = function(pn) return WINS.world[pn or 0] end,
            isOpen = function(pn) return WINS.world[pn or 0] ~= nil end,
        }
        W.open = open

        -- the engine: a pad plays for a player; a press goes to that slot's focus, else to the controller
        function W.bind(pn, id)
            CONN[id] = true
            local jd = { player = pn, id = id }
            JoypadState.players[pn + 1] = jd
            JoypadState.joypads[pn + 1] = jd
            CTL[id].joypad = jd
            return jd
        end
        function W.press(id, name)
            BTN[id][name] = true
            local ctl = CTL[id]
            local jd = ctl.joypad
            local f = jd and jd.focus
            if f and f.onJoypadDown then f:onJoypadDown(JoypadButton[name], jd) else ctl:onPressButtonNoFocus(JoypadButton[name]) end
        end
        function W.release(id, name)
            BTN[id][name] = false
            CTL[id]:onReleaseButton(JoypadButton[name])
        end
        function W.dpad(id, dir)
            BTN[id][DIR[dir]] = true
            local jd = CTL[id].joypad
            local f = jd and jd.focus
            if f and f[DIRFN[dir]] then f[DIRFN[dir]](f, jd) end
        end
        function W.dpadUp(id, dir) BTN[id][DIR[dir]] = false end
        function W.click() W.mouse = true end
        -- player 1 as seen through the calls that name no player
        function W.state()
            local w = F.getFocusedWindow()
            local el = w and F.getFocusedElement(w)
            local jd = JoypadState.players[1]
            rec(0, string.format("state %s %s cues=%s mode=%s chord=%s slot=%s", lab(w), el and el.id or "-",
                tostring(F.cuesVisible()), tostring(W.D.getMode()), tostring(W.C.getState()), lab(jd and jd.focus)))
        end
        -- 10 ms frames: the steps due, every OnTick, every OnRenderTick (a click lasts one frame)
        function W.run(toMs, script)
            script = script or {}
            local si = 1
            while clock - W.t0 < toMs do
                clock = clock + 10
                local now = clock - W.t0
                while script[si] and script[si].ms <= now do
                    script[si].fn()
                    if script[si].pn == 0 then W.state() end
                    si = si + 1
                end
                fireE("OnTick")
                fireE("OnRenderTick")
                W.mouse = false
            end
        end
        function W.after(ms) return W.run(clock - W.t0 + ms) end
        function W.mark() return #T end
        function W.since(n, pat)   -- a line after mark n matching pat
            for i = n + 1, #T do if T[i]:find(pat) then return T[i] end end
            return nil
        end
        return W
    end

    local function lines(T, pn)
        local out = {}
        for _, l in ipairs(T) do
            if pn == nil or l:match("^%s*%d+ p(%S+) ") == tostring(pn) then out[#out + 1] = l end
        end
        return out
    end
    local function has(T, pat) for _, l in ipairs(T) do if l:find(pat) then return true end end return false end
    -- a script: steps { ms, pn, fn }, merged in time order (same ms: the order they were written)
    local function merge(...)
        local all, seq = {}, 0
        for _, s in ipairs({ ... }) do
            for _, st in ipairs(s) do seq = seq + 1; st.seq = seq; all[#all + 1] = st end
        end
        table.sort(all, function(a, b) if a.ms ~= b.ms then return a.ms < b.ms end return a.seq < b.seq end)
        return all
    end
    local function steps(pn)
        local s = {}
        return s, function(ms, fn) s[#s + 1] = { ms = ms, pn = pn, fn = fn } end
    end

    -- player 1 on pad 0: the mouse first, then every pad feature (Hold LB + tap RB zooms in, Hold RB + tap LB out)
    local function p1(W)
        local s, at = steps(0)
        local P, R, D, U = W.press, W.release, W.dpad, W.dpadUp
        at(0, W.click)
        at(1000, function() W.bind(0, 0); P(0, "A") end)
        at(1080, function() R(0, "A") end)
        at(1200, function() P(0, "Y") end); at(1300, function() R(0, "Y") end)
        at(1500, function() P(0, "Y") end); at(1600, function() R(0, "Y") end)
        at(1800, function() D(0, "down") end); at(1850, function() U(0, "down") end)
        at(2000, function() D(0, "down") end); at(2800, function() U(0, "down") end)
        for i, ms in ipairs({ 3000, 3100, 3200 }) do
            at(ms, function() D(0, "right") end); at(ms + 50, function() U(0, "right") end)
        end
        at(3400, function() P(0, "LeftBump") end); at(3450, function() R(0, "LeftBump") end)
        at(3500, function() D(0, "left") end); at(3550, function() U(0, "left") end)
        at(3600, function() P(0, "A") end); at(3700, function() R(0, "A") end)
        at(3900, function() P(0, "A") end)
        at(4300, function() D(0, "down") end); at(4350, function() U(0, "down") end)
        at(4500, function() R(0, "A") end)
        at(4700, function() P(0, "X") end); at(4800, function() R(0, "X") end)
        at(5000, function() P(0, "X") end)
        at(5500, function() D(0, "down") end); at(5550, function() U(0, "down") end)
        at(5700, function() R(0, "X") end)
        at(5900, function() P(0, "B") end); at(5950, function() R(0, "B") end)
        at(6100, function() P(0, "RightBump") end); at(6150, function() R(0, "RightBump") end)
        at(6800, function() W.AX[0][2] = 1.0 end); at(6900, function() W.AX[0][2] = 0 end)
        at(7100, function() P(0, "LeftBump") end); at(7200, function() P(0, "RightBump") end)
        at(7250, function() R(0, "RightBump") end); at(7400, function() R(0, "LeftBump") end)
        at(7500, function() P(0, "RightBump") end); at(7600, function() P(0, "LeftBump") end)
        at(7650, function() R(0, "LeftBump") end); at(7800, function() R(0, "RightBump") end)
        at(8000, function() P(0, "Y") end); at(8080, function() R(0, "Y") end)
        at(8300, function() JoypadState.players[1].focus = MENU end)
        at(8400, function() W.F.reclaimEngineFocus() end)
        at(8600, function() P(0, "Y") end); at(9200, function() R(0, "Y") end)
        at(9300, function() W.mx = W.mx + 50 end)
        at(9400, W.click)
        return s
    end
    -- player 2 on pad 1, ZeD's windows not theirs: everything a pad does, between and across player 1's steps
    local function p2noise(W)
        local s, at = steps(1)
        local P, R, D, U = W.press, W.release, W.dpad, W.dpadUp
        at(100, function() W.AX[1][0] = 0.9 end); at(400, function() W.AX[1][0] = 0 end)
        at(450, function() W.AX[1][5] = 1.0 end); at(480, function() W.AX[1][5] = 0 end)
        at(500, function() P(1, "A") end); at(530, function() R(1, "A") end)
        at(600, function() P(1, "B") end); at(630, function() R(1, "B") end)
        at(700, function() P(1, "Y") end); at(750, function() R(1, "Y") end)
        at(1450, function() P(1, "RightBump") end); at(1460, function() P(1, "Y") end)
        at(1650, function() R(1, "Y") end); at(1700, function() R(1, "RightBump") end)
        at(2900, function() W.AX[1][2] = 1.0 end); at(3000, function() W.AX[1][2] = 0 end)
        at(4100, function() W.F.reclaimEngineFocus(1) end)
        at(5200, function() P(1, "LeftBump"); P(1, "RightBump") end)
        at(5300, function() R(1, "LeftBump"); R(1, "RightBump") end)
        at(6000, function() D(1, "up") end); at(6050, function() U(1, "up") end)
        at(6100, function() D(1, "left") end); at(6150, function() U(1, "left") end)
        at(6200, function() P(1, "Y") end); at(6600, function() R(1, "Y") end)
        at(8000, function() W.CONN[1] = false; W.fire("OnGamepadDisconnect", 1) end)
        at(8100, function() W.CONN[1] = true; W.fire("OnGamepadConnect", 1) end)
        return s
    end
    -- player 2 on pad 1 with ZeD's windows their own (the gate opened in the sim only): player 1's script on theirs
    local function p2own(W)
        local s, at = steps(1)
        local P, R, D, U = W.press, W.release, W.dpad, W.dpadUp
        at(1000, function() P(1, "Y") end); at(1080, function() R(1, "Y") end)
        at(1800, function() D(1, "down") end); at(1850, function() U(1, "down") end)
        at(2000, function() D(1, "down") end); at(2800, function() U(1, "down") end)
        for i, ms in ipairs({ 3000, 3100, 3200 }) do
            at(ms, function() D(1, "right") end); at(ms + 50, function() U(1, "right") end)
        end
        at(3400, function() P(1, "LeftBump") end); at(3450, function() R(1, "LeftBump") end)
        at(3500, function() D(1, "left") end); at(3550, function() U(1, "left") end)
        at(3600, function() P(1, "A") end); at(3700, function() R(1, "A") end)
        at(3900, function() P(1, "A") end)
        at(4300, function() D(1, "down") end); at(4350, function() U(1, "down") end)
        at(4500, function() R(1, "A") end)
        at(4700, function() P(1, "X") end); at(4800, function() R(1, "X") end)
        at(5000, function() P(1, "X") end)
        at(5500, function() D(1, "down") end); at(5550, function() U(1, "down") end)
        at(5700, function() R(1, "X") end)
        at(5900, function() P(1, "B") end); at(5950, function() R(1, "B") end)
        at(6100, function() P(1, "RightBump") end); at(6150, function() R(1, "RightBump") end)
        at(6850, function() W.AX[1][2] = 1.0 end); at(6950, function() W.AX[1][2] = 0 end)
        at(7100, function() P(1, "LeftBump") end); at(7200, function() P(1, "RightBump") end)
        at(7250, function() R(1, "RightBump") end); at(7400, function() R(1, "LeftBump") end)
        at(7500, function() P(1, "RightBump") end); at(7600, function() P(1, "LeftBump") end)
        at(7650, function() R(1, "LeftBump") end); at(7800, function() R(1, "RightBump") end)
        at(8000, function() P(1, "Y") end); at(8080, function() R(1, "Y") end)
        at(8300, function() P(1, "Y") end); at(8900, function() R(1, "Y") end)
        at(8800, function()   -- (player 2's Y hold fired at 8700; player 1's own fires at 9000)
            W.probe = { reg = W.F.isRegistered(W.WINS.char[0]), foc = W.F.getFocusedWindow() == W.WINS.char[0],
                        gone = W.WINS.char[1] == nil and W.WINS.world[1] == nil }
        end)
        return s
    end
    local GATE2 = function(pn) return pn == nil or pn == 0 or pn == 1 end

    -- player 1's run before split-screen's input per player (taken from the files as they were; ZEDQA_S1_DUMP=1
    -- prints the run as it is now)
    local GOLDEN = [[
    0 p0 [ZeD.Input] ActionMap loaded - 18 actions registered
    0 p0 [ZeD.Input] BumperChord loaded - no arming timeout, hold-and-tap model
    0 p0 [ZeD.Input] InputModeDetector loaded - awaiting first input event
    0 p0 [ZeD] QuickChords: a bumper held with A, B, X, Y, L3 or R3 runs a quick action
   10 p0 state nil - cues=false mode=unknown chord=IDLE slot=nil
   20 p0 [ZeD.Input] mode: unknown -> kbm
 1000 p0 game press A
 1000 p0 state nil - cues=false mode=kbm chord=IDLE slot=nil
 1000 p0 [ZeD.Input] mode: kbm -> gamepad
 1000 p0 pair
 1000 p0 open char0
 1000 p0 [ZeD.Input] Focus: register: char0 (1 registered)
 1000 p0 [ZeD.Input] Focus: claim: nil -> char0
 1000 p0 char0 r1 onFocus
 1000 p0 engine focus char0
 1000 p0 ignore aim
 1000 p0 focus char0 <- nil
 1000 p0 open world0
 1000 p0 [ZeD.Input] Focus: register: world0 (2 registered)
 1000 p0 [ZeD.Input] Focus: claim: char0 -> world0
 1000 p0 world0 r1 onFocus
 1000 p0 engine focus world0
 1000 p0 ignore aim
 1000 p0 focus world0 <- char0
 1080 p0 game release A
 1080 p0 state world0 r1 cues=true mode=gamepad chord=IDLE slot=world0
 1200 p0 state world0 r1 cues=true mode=gamepad chord=IDLE slot=world0
 1300 p0 game release Y
 1300 p0 state world0 r1 cues=true mode=gamepad chord=IDLE slot=world0
 1300 p0 shade char0
 1300 p0 shade world0
 1300 p0 engine focus nil
 1300 p0 [ZeD.Input] Focus: release: world0 -> nil
 1300 p0 focus nil <- world0
 1300 p0 [ZeD.Input] Focus: Y tap - hide pair
 1500 p0 game press Y
 1500 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 1600 p0 game release Y
 1600 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 1600 p0 unshade char0
 1600 p0 unshade world0
 1600 p0 [ZeD.Input] Focus: claim: nil -> char0
 1600 p0 engine focus char0
 1600 p0 ignore aim
 1600 p0 focus char0 <- nil
 1600 p0 [ZeD.Input] Focus: Y tap - unhide pair, Character focus
 1800 p0 [ZeD.Input] Focus: spatial down -> flat[2/6] (cone) zone=list [char0]
 1800 p0 char0 r2 onFocus
 1800 p0 state char0 r2 cues=true mode=gamepad chord=IDLE slot=char0
 1850 p0 state char0 r2 cues=true mode=gamepad chord=IDLE slot=char0
 2000 p0 [ZeD.Input] Focus: spatial down -> flat[3/6] (cone) zone=list [char0]
 2000 p0 char0 r3 onFocus
 2000 p0 state char0 r3 cues=true mode=gamepad chord=IDLE slot=char0
 2250 p0 [ZeD.Input] Focus: spatial down -> flat[4/6] (cone) zone=list [char0]
 2250 p0 char0 r4 onFocus
 2800 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 3000 p0 [ZeD.Input] Focus: spatial right -> flat[6/6] (half) zone=btns [char0]
 3000 p0 char0 b2 onFocus
 3000 p0 state char0 b2 cues=true mode=gamepad chord=IDLE slot=char0
 3050 p0 state char0 b2 cues=true mode=gamepad chord=IDLE slot=char0
 3100 p0 [ZeD.Input] Focus: spatial right -> window world0
 3100 p0 [ZeD.Input] Focus: claim: char0 -> world0
 3100 p0 engine focus world0
 3100 p0 ignore aim
 3100 p0 focus world0 <- char0
 3100 p0 state world0 r1 cues=true mode=gamepad chord=IDLE slot=world0
 3150 p0 state world0 r1 cues=true mode=gamepad chord=IDLE slot=world0
 3200 p0 [ZeD.Input] Focus: spatial right -> flat[5/6] (cone) zone=btns [world0]
 3200 p0 world0 b1 onFocus
 3200 p0 state world0 b1 cues=true mode=gamepad chord=IDLE slot=world0
 3250 p0 state world0 b1 cues=true mode=gamepad chord=IDLE slot=world0
 3400 p0 pair
 3400 p0 [ZeD.Input] Focus: claim: world0 -> char0
 3400 p0 engine focus char0
 3400 p0 ignore aim
 3400 p0 focus char0 <- world0
 3400 p0 state char0 b2 cues=true mode=gamepad chord=IDLE slot=char0
 3450 p0 game release LeftBump
 3450 p0 state char0 b2 cues=true mode=gamepad chord=IDLE slot=char0
 3500 p0 [ZeD.Input] Focus: spatial left -> back to r4 [char0]
 3500 p0 char0 r4 onFocus
 3500 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 3550 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 3600 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 3700 p0 game release A
 3700 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 3700 p0 char0 r4 onActivate
 3900 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 4250 p0 char0 r4 onHoldActivate
 4300 p0 char0 r4 onPaint
 4300 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 4350 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 4500 p0 game release A
 4500 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 4700 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 4800 p0 game release X
 4800 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 4800 p0 char0 r4 onContextMenu
 5000 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 5350 p0 char0 r4 onHoldContextDrag nil
 5500 p0 char0 r4 onHoldContextDrag down
 5500 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 5550 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 5700 p0 game release X
 5700 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 5700 p0 char0 r4 onHoldContextRelease
 5900 p0 char0 r4 onCancel
 5900 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 5950 p0 game release B
 5950 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 6100 p0 pair
 6100 p0 [ZeD.Input] Focus: claim: char0 -> world0
 6100 p0 engine focus world0
 6100 p0 ignore aim
 6100 p0 focus world0 <- char0
 6100 p0 state world0 b1 cues=true mode=gamepad chord=IDLE slot=world0
 6150 p0 game release RightBump
 6150 p0 state world0 b1 cues=true mode=gamepad chord=IDLE slot=world0
 6800 p0 state world0 b1 cues=true mode=gamepad chord=IDLE slot=world0
 6800 p0 [ZeD.Input] Focus: aiming-escape magSq=1 world0
 6800 p0 [ZeD.Input] Focus: hideAll (aim-RS)
 6800 p0 shade char0
 6800 p0 shade world0
 6800 p0 engine focus nil
 6800 p0 [ZeD.Input] Focus: release: world0 -> nil
 6800 p0 focus nil <- world0
 6900 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 7100 p0 game press LeftBump
 7100 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 7100 p0 [ZeD.Input] chord: IDLE -> LB_HELD
 7200 p0 game press RightBump
 7200 p0 state nil - cues=true mode=gamepad chord=LB_HELD slot=nil
 7200 p0 [ZeD.Input] chord fire: zoom-in
 7200 p0 zoom -1
 7200 p0 [ZeD.Input] chord: LB_HELD -> CONSUMED
 7250 p0 game release RightBump
 7250 p0 state nil - cues=true mode=gamepad chord=CONSUMED slot=nil
 7400 p0 game release LeftBump
 7400 p0 state nil - cues=true mode=gamepad chord=CONSUMED slot=nil
 7400 p0 [ZeD.Input] chord: CONSUMED -> IDLE
 7500 p0 game press RightBump
 7500 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 7500 p0 [ZeD.Input] chord: IDLE -> RB_HELD
 7600 p0 game press LeftBump
 7600 p0 state nil - cues=true mode=gamepad chord=RB_HELD slot=nil
 7600 p0 [ZeD.Input] chord fire: zoom-out
 7600 p0 zoom 1
 7600 p0 [ZeD.Input] chord: RB_HELD -> CONSUMED
 7650 p0 game release LeftBump
 7650 p0 state nil - cues=true mode=gamepad chord=CONSUMED slot=nil
 7800 p0 game release RightBump
 7800 p0 state nil - cues=true mode=gamepad chord=CONSUMED slot=nil
 7800 p0 [ZeD.Input] chord: CONSUMED -> IDLE
 8000 p0 game press Y
 8000 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 8080 p0 game release Y
 8080 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 8080 p0 unshade char0
 8080 p0 unshade world0
 8080 p0 [ZeD.Input] Focus: claim: nil -> char0
 8080 p0 engine focus char0
 8080 p0 ignore aim
 8080 p0 focus char0 <- nil
 8080 p0 [ZeD.Input] Focus: Y tap - unhide pair, Character focus
 8300 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=menu
 8400 p0 engine focus char0
 8400 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 8600 p0 state char0 r4 cues=true mode=gamepad chord=IDLE slot=char0
 9000 p0 [ZeD.Input] Focus: Y hold - close pair
 9000 p0 [ZeD.Input] Focus: closeAll
 9000 p0 [ZeD.Input] Focus: unregister: char0 (1 registered)
 9000 p0 [ZeD.Input] Focus: transfer: char0 -> world0
 9000 p0 engine focus world0
 9000 p0 ignore aim
 9000 p0 focus world0 <- char0
 9000 p0 close char0
 9000 p0 [ZeD.Input] Focus: unregister: world0 (0 registered)
 9000 p0 [ZeD.Input] Focus: release: world0 -> nil
 9000 p0 engine focus nil
 9000 p0 focus nil <- world0
 9000 p0 close world0
 9200 p0 game release Y
 9200 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 9300 p0 state nil - cues=true mode=gamepad chord=IDLE slot=nil
 9400 p0 state nil - cues=false mode=gamepad chord=IDLE slot=nil
 9410 p0 [ZeD.Input] mode: gamepad -> kbm
]]
    local function goldenCheck(name, T)
        local want = {}
        for l in GOLDEN:gmatch("[^\n]+") do want[#want + 1] = l end
        local got = lines(T, 0)
        local n = math.max(#want, #got)
        for i = 1, n do
            if want[i] ~= got[i] then
                check(name, false, "line " .. i .. ": want [" .. tostring(want[i]) .. "] got [" .. tostring(got[i]) .. "]")
                return
            end
        end
        check(name, #want > 50, #want)
    end
    local function play(name, opts, ...)
        local W
        local fs = { ... }
        local ok, err = pcall(function()
            W = world(opts)
            local parts = {}
            for _, f in ipairs(fs) do parts[#parts + 1] = f(W) end
            W.run(9600, merge(unpack(parts)))
        end)
        check(name .. " runs", ok, err)
        return W or { T = {} }
    end

    -- T1: player 1 alone
    local T1 = play("T1", nil, p1)
    if os.getenv("ZEDQA_S1_DUMP") == "1" then
        realPrint("-- S1 GOLDEN BEGIN")
        for _, l in ipairs(lines(T1.T, 0)) do realPrint(l) end
        realPrint("-- S1 GOLDEN END")
    end
    goldenCheck("T1 player 1 alone: the run is the one before split-screen, line for line", T1.T)
    -- T2: player 2 on pad 2, ZeD's windows not theirs
    local T2 = play("T2", nil, p1, function(W) W.bind(1, 1); return {} end, p2noise)
    goldenCheck("T2 player 2 on their own pad (stick, trigger, buttons, aim, a quick chord, LB+RB, unplugged): "
        .. "player 1's run unchanged", T2.T)
    check("U12 player 2's quick chord never swallows player 1's Y release", has(lines(T2.T, 0), "^ *1600 p0 game release Y"))
    check("U2 player 2's stick and trigger leave player 1 on the mouse and keyboard",
        not has(lines(T2.T, 0), "^ *[1-9]%d%d p0 .*mode: kbm %-> gamepad"))
    -- T3: the gate opened for player 2 in the sim only: player 2 runs their own windows at the same moments
    local T3 = play("T3", { gate = GATE2 }, p1, function(W) W.bind(1, 1); return {} end, p2own)
    goldenCheck("T3 player 2 with ZeD windows of their own at the same moments: player 1's run unchanged", T3.T)
    local m2 = lines(T3.T, 1)
    check("P1 player 2's Y opens their pair and takes their own pad", has(m2, "p1 engine focus char1")
        and not has(lines(T3.T, 0), "char1") and not has(lines(T3.T, 0), "world1"))
    local moves = 0
    for _, l in ipairs(m2) do if l:find("^ *2%d%d%d p1 char1 r%d onFocus") then moves = moves + 1 end end
    check("P2 player 2's held D-pad moves and repeats on char1", moves >= 2, moves)
    check("P3 player 2's A hold marks a row and paints with the D-pad", has(m2, "char1 r%d onHoldActivate")
        and has(m2, "char1 r%d onPaint"))
    check("P4 player 2's LB+RB zooms player 2", has(m2, "p1 zoom %-1") and has(m2, "p1 zoom 1"))
    check("P5 player 2's aim rolls up their own pair", has(m2, "p1 shade char1") and has(m2, "p1 shade world1"))
    local pr = T3.probe or {}
    check("P6 player 2's Y hold closes their pair only (player 1's still registered and focused)",
        pr.reg == true and pr.foc == true and pr.gone == true, tostring(pr.reg) .. tostring(pr.foc) .. tostring(pr.gone))
    check("U16 ZeD_FocusChanged names the player", has(m2, "p1 focus char1"))

    -- the input mode: player 1's alone; players 2-4 are always on a pad
    local ok, err = pcall(function()
        local W = world({ coop = { instance = { joypadData = { id = 3 }, playerIndex = 1 } } })
        W.bind(1, 1)
        W.click(); W.after(100)
        check("U1 a second player is always on a pad, the first on the mouse", W.D.getMode(1) == "gamepad"
            and W.D.getMode() == "kbm" and W.D.getMode(0) == "kbm", tostring(W.D.getMode(1)) .. " " .. tostring(W.D.getMode()))
        W.AX[1][0] = 0.9; W.press(1, "A"); W.after(300); W.release(1, "A"); W.AX[1][0] = 0; W.after(300)
        check("U2 pad 2's stick and buttons leave player 1 on the mouse and keyboard", W.D.getMode() == "kbm", W.D.getMode())
        check("U3 ... and never open player 1's pair", not has(W.T, "p0 pair"))
        W.CONN[3] = true; W.AX[3][2] = 1.0; W.after(300); W.AX[3][2] = 0
        check("C2 a pad still in character creation for a new player speaks for nobody", W.D.getMode() == "kbm", W.D.getMode())
        W.CONN[2] = true; W.AX[2][0] = 0.9; W.after(300); W.AX[2][0] = 0
        check("U4 a pad nobody plays with still switches player 1 to the pad", W.D.getMode() == "gamepad", W.D.getMode())
    end)
    check("S1 mode probe runs", ok, err)

    -- player 1's pad unplugged while player 2's stays: player 1 is back on the mouse and keyboard
    ok, err = pcall(function()
        local W = world()
        W.bind(0, 0); W.bind(1, 1)
        W.press(0, "A"); W.after(300); W.release(0, "A"); W.after(300)
        W.CONN[0] = false; W.fire("OnGamepadDisconnect", 0); W.after(50)
        check("U5 player 1's pad gone, player 2's left: player 1 falls back to the mouse and keyboard", W.D.getMode() == "kbm", W.D.getMode())
    end)
    check("S1 unplug probe runs", ok, err)

    -- aiming, the engine focus handed back, the reads that name a player
    ok, err = pcall(function()
        local W = world({ coop = { instance = { joypadData = { id = 2 }, playerIndex = 1 } } })
        W.bind(0, 0); W.bind(1, 1); W.CONN[2] = true
        W.press(0, "A"); W.after(100); W.release(0, "A"); W.after(800)
        local fw = W.F.getFocusedWindow()
        check("S1 harness: the pad opened player 1's pair", fw == W.WINS.world[0], fw and fw._zedLabel)
        W.AX[2][2] = 1.0; W.after(100); W.AX[2][2] = 0; W.after(50)
        check("C2 a creation-stage pad's right stick leaves player 1's windows and focus", W.F.getFocusedWindow() == fw
            and not has(W.T, "aiming%-escape"))
        W.AX[1][2] = 1.0; W.after(100); W.AX[1][2] = 0; W.after(50)
        check("U6 player 2 aiming leaves player 1's windows and focus", W.F.getFocusedWindow() == fw
            and not has(W.T, "aiming%-escape"))
        local slot = JoypadState.players[1]
        slot.focus = MENU
        W.F.reclaimEngineFocus(1)
        check("U8 a second player's reclaim leaves player 1's pad on its menu", slot.focus == MENU, lab(slot.focus))
        W.F.reclaimEngineFocus()
        check("U9 player 1's reclaim puts their pad back on their window", slot.focus == fw, lab(slot.focus))
        check("U17 no player named is player 1", W.F.getFocusedWindow() == W.F.getFocusedWindow(0)
            and W.F.cuesVisible() == W.F.cuesVisible(0) and W.C.getState() == W.C.getState(0) and W.D.getMode() == W.D.getMode(0))
        check("U18 player 2 holds no window while player 1 holds one", W.F.getFocusedWindow(1) == nil)
        W.mx = W.mx + 50; W.after(30)
        check("U15 the mouse moved: player 1's marks go, a second player's stay", W.F.cuesVisible() == false
            and W.F.cuesVisible(1) == true, tostring(W.F.cuesVisible()) .. " " .. tostring(W.F.cuesVisible(1)))
        W.AX[0][2] = 1.0; W.after(100); W.AX[0][2] = 0; W.after(50)
        check("U7 player 1 aiming still rolls their windows up", W.F.getFocusedWindow() == nil and has(W.T, "aiming%-escape"))
        W.press(0, "LeftBump"); W.after(50)
        check("U19 player 1's chord is theirs alone", W.C.getState() == "LB_HELD" and W.C.getState(1) == "IDLE",
            W.C.getState() .. " " .. W.C.getState(1))
        W.release(0, "LeftBump"); W.after(50)
    end)
    check("S1 aim probe runs", ok, err)

    -- pad 2's presses on player 1's window (its slot focus forced there) and on player 1's dash: dropped
    ok, err = pcall(function()
        local W = world()
        W.bind(0, 0); W.bind(1, 1)
        W.press(0, "A"); W.after(100); W.release(0, "A"); W.after(800)
        local fw = W.F.getFocusedWindow()
        local slot2 = JoypadState.players[2]
        slot2.focus = fw
        local n = W.mark()
        W.press(1, "A"); W.after(100); W.release(1, "A"); W.after(100)
        W.press(1, "X"); W.after(100); W.release(1, "X"); W.after(100)
        W.dpad(1, "down"); W.after(50); W.dpadUp(1, "down"); W.after(50)
        check("U10 pad 2's A, X and D-pad on player 1's window do nothing", not W.since(n, "world0 r%d"), W.since(n, "world0 r%d"))
        n = W.mark()
        W.press(0, "A"); W.after(100); W.release(0, "A"); W.after(50)
        check("U10 (control) player 1's own A on it fires", W.since(n, "world0 r%d onActivate") ~= nil)
        local dash = setmetatable({ playerNum = 0, _zedLabel = "dash0", _focusEntryZone = nil }, { __index = ZeD_Panel })
        dash._focusRing = { { zone = "dash", focusable = true, focusedElementIdx = 1, elements = {
            { id = "d1", x = 0, y = 0, w = 10, h = 10, onActivate = function() W.rec(0, "dash0 d1 onActivate") end } } } }
        dash._focusIdx = 1
        W.F.registerWindow(dash); W.F.claimFocus(dash)
        slot2.focus = dash
        n = W.mark()
        W.press(1, "A"); W.after(100); W.release(1, "A"); W.after(100)
        check("U10 pad 2's A on player 1's dash does nothing", not W.since(n, "dash0 d1"))
        W.press(0, "A"); W.after(100); W.release(0, "A"); W.after(50)
        check("U10 (control) player 1's A on their dash fires", W.since(n, "dash0 d1 onActivate") ~= nil)
    end)
    check("S1 stub probe runs", ok, err)

    -- player 1's slot without its pad (id -1 reads every pad): pad 2's Y opens nothing for player 1; a hold dies quietly
    ok, err = pcall(function()
        local W = world()
        W.bind(0, 0); W.bind(1, 1)
        W.press(0, "A"); W.after(100); W.release(0, "A"); W.after(300)
        W.F.releaseFocus(); W.after(50)
        JoypadState.players[1].id = -1
        local n = W.mark()
        W.BTN[1].Y = true; W.after(100); W.BTN[1].Y = false; W.after(100)
        check("U11 player 1's slot with no pad: pad 2's Y opens nothing for player 1", not W.since(n, "Y tap"), W.since(n, "Y tap"))
        JoypadState.players[1].id = 0
        W.F.claimFocus(W.WINS.char[0]); W.after(50)
        W.press(0, "A"); W.after(50)
        JoypadState.players[1].id = -1
        n = W.mark()
        W.after(100); W.BTN[0].A = false; W.after(100)
        check("C3 player 1's A held when their slot loses its pad is dropped, not a tap", not W.since(n, "onActivate"))
        JoypadState.players[1].id = 0
        W.press(0, "A"); W.after(50)
        n = W.mark()
        W.CONN[0] = false; W.after(100); W.BTN[0].A = false; W.CONN[0] = true; W.after(100)
        check("C3 player 1's A held when the pad unplugs is dropped, not a tap", not W.since(n, "onActivate"))
    end)
    check("S1 slot probe runs", ok, err)

    -- the quick chords per pad
    ok, err = pcall(function()
        local W = world()
        W.bind(0, 0); W.bind(1, 1)
        W.press(0, "A"); W.after(100); W.release(0, "A"); W.after(300)
        W.press(1, "RightBump"); W.press(1, "A"); W.after(50); W.release(1, "A"); W.release(1, "RightBump"); W.after(50)
        check("U13 player 1's focused window does not block pad 2's quick chord", has(W.T, "p1 chord RB%+A"))
        W.BTN[0].RightBump = true
        check("U14 player 1's own quick chord stays blocked while their window holds the pad",
            W.Q.onPress(JoypadState.players[1], Joypad.AButton) == false)
        W.BTN[0].RightBump = false
        -- a pad unplugged with a chord's button down, plugged back in: its next release is the game's again
        W.press(1, "RightBump"); W.press(1, "Y"); W.after(50)
        W.CONN[1] = false; W.fire("OnGamepadDisconnect", 1); W.after(50)
        W.BTN[1].Y = false; W.BTN[1].RightBump = false; W.CONN[1] = true; W.fire("OnGamepadConnect", 1); W.after(50)
        local n = W.mark()
        W.release(1, "Y")
        check("C6 a chord's button left down on an unplugged pad leaves nothing behind", W.since(n, "p1 game release Y") ~= nil)
        -- a controller whose own id is not set (zedqa_quick_chords.lua's): the press and release still pair up
        W.F.releaseFocus(); W.after(50)
        local fake = setmetatable({ joypad = { player = 0, id = 0 } }, JoypadControllerData)
        W.Q.qaBumper = "RB"
        fake:onPressButtonNoFocus(Joypad.YButton)
        n = W.mark()
        fake:onReleaseButton(Joypad.YButton)
        W.Q.qaBumper = nil
        check("C9 (setup) the chord ran and its release was swallowed", has(W.T, "p0 chord RB%+Y") and not W.since(n, "game release"))
        n = W.mark()
        W.press(0, "Y"); W.release(0, "Y")
        check("C9 a controller with no id of its own leaves no chord behind on its pad", W.since(n, "p0 game release Y") ~= nil)
    end)
    check("S1 quick chord probe runs", ok, err)

    -- joining, dying and coming back, the gate opened for player 2 in the sim only
    ok, err = pcall(function()
        local W = world({ gate = GATE2 })
        W.bind(0, 0); W.bind(1, 1)
        W.press(0, "A"); W.after(100); W.release(0, "A"); W.after(300)
        local w0 = W.F.getFocusedWindow()
        W.press(1, "Y"); W.after(50); W.release(1, "Y"); W.after(100)
        check("S1 harness: player 2's Y opened their pair", W.F.getFocusedWindow(1) == W.WINS.char[1])
        W.WINS.char[1]:close(); W.after(20)
        check("P7 closing player 2's focused window hands their focus to their other window",
            W.F.getFocusedWindow(1) == W.WINS.world[1] and W.F.getFocusedWindow(0) == w0)
        -- player 1's seat taken again: the holds go, the window stays
        W.press(0, "A"); W.after(50)
        W.fire("OnCreatePlayer", 0, W.PL[0])
        local st = W.F._st and W.F._st[0]
        check("C4 OnCreatePlayer(0) drops player 1's holds and keeps their window", st ~= nil and st.aHeld == false
            and W.F.getFocusedWindow(0) == w0)
        local n = W.mark()
        W.release(0, "A"); W.after(100)
        check("C4 ... so the A let go after it is no tap", not W.since(n, "onActivate"))
        -- player 2's pad gone mid-hold: no tap
        W.press(1, "A"); W.after(100); W.release(1, "A"); W.after(50)
        check("C3 (control) player 2's A tap fires on their window", has(W.T, "world1 r%d onActivate"))
        W.press(1, "A"); W.after(50)
        n = W.mark()
        W.CONN[1] = false; W.after(100); W.BTN[1].A = false; W.CONN[1] = true; W.after(100)
        check("C3 player 2's A held when their pad unplugs is dropped, not a tap", not W.since(n, "onActivate"))
        -- death with the Character window's handler running first (file order not relied on)
        ZeD_CharacterWindow.ensureBothOpenForGamepad(1); W.after(50)
        local c1 = W.WINS.char[1]
        W.press(1, "A"); W.after(400)
        check("C5 (setup) player 2's A hold armed a painted run", c1 and c1._gpPaint ~= nil)
        table.insert(Events.OnPlayerDeath.fns, 1, function(p)
            local pn = p:getPlayerNum()
            for _, k in ipairs({ "char", "world" }) do local w = W.WINS[k][pn]; if w then w:close() end end
        end)
        W.PL[1].dead = true
        local slot2 = JoypadState.players[2]
        slot2.player = nil; slot2.focus = nil   -- (vanilla's JoypadState.onPlayerDeath)
        n = W.mark()
        W.fire("OnPlayerDeath", W.PL[1])
        check("C5 a dead player's closing windows push nothing onto their post-death screen", not W.since(n, "p1 engine focus"),
            W.since(n, "p1 engine focus"))
        check("C5 ... and their painted run is cleared", c1 and c1._gpPaint == nil)
        W.BTN[1].A = false; W.after(50)
        n = W.mark()
        W.press(1, "Y"); W.after(100); W.release(1, "Y"); W.after(100)
        W.press(1, "LeftBump"); W.press(1, "RightBump"); W.after(50); W.release(1, "LeftBump"); W.release(1, "RightBump"); W.after(50)
        check("C1 a dead player's Y and LB+RB on the post-death screen open and zoom nothing",
            not W.since(n, "p1 pair") and not W.since(n, "p1 zoom"))
        -- vanilla's accept binds the number again before the new character exists; Y and LB held through it
        slot2.player = 1
        W.BTN[1].Y = true; W.BTN[1].LeftBump = true; W.after(100)
        W.PL[1] = W.mkPlayer(1)
        W.fire("OnCreatePlayer", 1, W.PL[1])
        W.after(200)
        check("C1 LB held through OnCreatePlayer is no new chord", W.C.getState(1) == "IDLE", W.C.getState(1))
        W.BTN[1].Y = false; W.BTN[1].LeftBump = false; W.after(100)
        check("C1 Y held through OnCreatePlayer opens nothing", not W.since(n, "p1 pair") and not W.since(n, "Y tap"))
        W.press(1, "Y"); W.after(50); W.release(1, "Y"); W.after(100)
        check("P8 after a death and a new character, player 2's next Y opens their pair afresh",
            W.since(n, "p1 pair") ~= nil and W.F.getFocusedWindow(1) == W.WINS.char[1] and W.F.getFocusedWindow(0) == w0)
    end)
    check("S1 join and death probe runs", ok, err)

    -- the callers: the four reclaims and the dash's stubs name their player
    local cm, cl, mpl, maps = src("ZeD_ContextMenu.lua"), src("ZeD_ContextList.lua"), src("ZeD_MpLeftovers.lua"), src("MapsTab.lua")
    local function count(s, pat) local n = 0; for _ in s:gmatch(pat) do n = n + 1 end; return n end
    check("U21 the four reclaims pass their player", cm:find("reclaimEngineFocus(self.player)", 1, true) ~= nil
        and cl:find("reclaimEngineFocus(self.player)", 1, true) ~= nil and mpl:find("reclaimEngineFocus(pn)", 1, true) ~= nil
        and maps:find("reclaimEngineFocus(pn)", 1, true) ~= nil and not cm:find("reclaimEngineFocus()", 1, true)
        and not cl:find("reclaimEngineFocus()", 1, true) and not mpl:find("reclaimEngineFocus()", 1, true)
        and not maps:find("reclaimEngineFocus()", 1, true))
    check("U22 the dash's five stubs gate on the pressing pad's player",
        count(panelSrc, "getFocusedWindow%(joypadData and joypadData%.player%) == self") == 5)

    for _, k in ipairs(GLOBALS) do _G[k] = saved[k] end
end

-- ---------------------------------------------------------------------------
section("MONTHS")
-- ---------------------------------------------------------------------------
do
    local MON = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
    -- the value of a key in a UI.json (one key a line, as the files are kept)
    local function value(src, key)
        return src:match('\n%s*"' .. key .. '"%s*:%s*"([^"]*)"')
    end
    -- lower case: no ASCII capital first, and no capital accented letter (UTF-8 C3 80..C3 9E)
    local function lowerFirst(s)
        if not s or s == "" then return false end
        local b1, b2 = s:byte(1), s:byte(2)
        if b1 >= 65 and b1 <= 90 then return false end
        if b1 == 0xC3 and b2 and b2 >= 0x80 and b2 <= 0x9E then return false end
        if b1 == 0xC5 and b2 and b2 % 2 == 0 and b2 >= 0x80 then return false end   -- (Latin Extended-A capitals)
        return true
    end
    for _, L in ipairs({ "FR", "HU" }) do
        local src = readFile(LUA .. "shared/Translate/" .. L .. "/UI.json") or ""
        local bad = {}
        for _, fam in ipairs({ "Journal", "MainMenu" }) do
            for _, m in ipairs(MON) do
                local v = value(src, "UI_ZeD_" .. fam .. "_Month" .. m)
                if not lowerFirst(v) then bad[#bad + 1] = fam .. m .. "=" .. tostring(v) end
            end
        end
        check(L .. ": the month words are lower case in dates", #bad == 0, table.concat(bad, " "))
    end
    local en = readFile(LUA .. "shared/Translate/EN/UI.json") or ""
    local caps = 0
    for _, m in ipairs(MON) do if value(en, "UI_ZeD_Journal_Month" .. m) == m then caps = caps + 1 end end
    check("English keeps its capitals", caps == 12, caps)
    local de = readFile(LUA .. "shared/Translate/DE/UI.json") or ""
    check("German keeps its capitals (nouns)", value(de, "UI_ZeD_Journal_MonthJan") == "Jan")
    -- every month in FR and HU's dates puts something before the month (the day or the year) except HU's own
    -- month-first formats, where Hungarian writes the short month in lower case too
    local fr = readFile(LUA .. "shared/Translate/FR/UI.json") or ""
    check("French dates put the day first (the month never starts the text)", value(fr, "UI_ZeD_Journal_EntryStamp"):find("%%3 %%2") ~= nil
        and value(fr, "UI_ZeD_Tk_ShortDate") == "%2 %1")
end

print("known_issues_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
