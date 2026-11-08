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
