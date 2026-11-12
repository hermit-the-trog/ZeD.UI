-- ZeDUI/tools/qa/zedqa_console_commands.lua  (Nov 12 2026, QA; the Lua console's Commands page)
-- The game runs with -debug, single player. The script drives ZeD's Lua console (ZeD.DebugConsole,
-- ZeD.ConsoleCommands) against the real game:
--   1 the Commands page opens from the strip; every command's help text is the game's own (getText finds each
--     UI_ServerOptionDesc key: NOTE any that come back as the key); shot
--   2 single player: every command shown, each with its debug-menu way; the windows a pick opens exist in this build
--     (ISAdminPowerUI, ISItemsListViewer, ISPlayerStatsUI, ClimateControlDebug, ISGeneralDebug, ISDebugMenu)
--   3 a pick of /godmode opens the Cheats window (shot), shut again; the band's keycap names it
--   4 the search: "weather" and "ban" narrow the list (shot)
--   5 the controller hand on the page (DC.qaJoy): strip, list, band (shots)
-- Nothing is sent: in single player there is no server. The windows opened are closed again.
--
-- On a server (by hand, the multiplayer check kit; this script does not run there): host or join with an admin
-- role and -debug, open the console's Commands page, and check
--   * "Your role: Admin" and the full list; switch to a user role (/setaccesslevel "<name>" "none" from another admin)
--     and see /kickuser and the rest disappear
--   * pick /players, Send: the server's answer arrives in chat (this is the proof that SendCommandToServer works from
--     the console); /servermsg "test" reaches everyone
--   * pick /removezombies: Send asks in the band; Cancel sends nothing; Send sends
--   * a chat channel (/say hi) goes as chat
-- grep "ZEDQA concmd"; shots zqa_concmd_*.png.
local TAG = "concmd"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local DC = ZeD and ZeD.DebugConsole
local CC = ZeD and ZeD.ConsoleCommands
if not (p and DC and CC) then say("ERR ZeD's console or its command list is not loaded"); say("DONE"); return end
if not DC.debug() then say("NOTE the game is not running with -debug: there is no console to check (run with -debug)"); say("DONE"); return end
if not DC.exists() then say("NOTE the game's console is not on the screen list yet (DC.exists is false); nothing to check"); say("DONE"); return end
if isClient() then say("NOTE this is a server: this script checks single player only; see its header for the server check"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_concmd_" .. n .. ".png") end) end

local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local cleanups = {}
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    cleanups = {}
    say("checks: passes=" .. passes .. " misses=" .. misses)
    say("DONE")
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
    qc = qc + 1
    if qc >= s.wait then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end

local jc = DC.game()
local wasUp = DC.up(jc)
local function flag(v) pcall(function() jc:setVisible(v) end) end
local function win() return DC.win end
local function shutCheats() pcall(function() if ISAdminPowerUI and ISAdminPowerUI.instance then ISAdminPowerUI.instance:close() end end) end
onCleanup(function()
    DC.qaJoy = nil
    shutCheats()
    local w = win()
    if w then
        pcall(function() w.cq:setText(""); w.chat:setText("") end)
        w.csel = nil
        w:setPage("log")
        w.zone = "input"
    end
    flag(wasUp)
end)

step(1, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    flag(false)
end)
step(20, function() flag(true) end)
-- ===== 1. the page, the game's help texts
step(30, function()
    check(DC.isOpen(), "1: the flag opens ZeD's Lua console")
    local w = win()
    w:setPage("cmds")
    check(w.page == "cmds", "1: the Commands page")
    local missing = {}
    for _, c in ipairs(CC.list) do
        if string.sub(c.help, 1, 7) ~= "UI_ZeD_" and CC.does(c) == "" then missing[#missing + 1] = c.name end
    end
    check(#missing == 0, "1: every game help key has the game's words (" .. (#missing > 0 and table.concat(missing, ",") or "all") .. ")")
end)
step(10, function()
    shot("page")
    local w = win()
    check(w._cItems ~= nil and #w._cItems > 10, "1: the list laid out (" .. tostring(w._cItems and #w._cItems) .. " rows)")
    -- ===== 2. single player: all shown, the openers there
    check(not CC.server(), "2: single player")
    local _, n = CC.shown("")
    check(n == #CC.list, "2: every command shown (" .. n .. " of " .. #CC.list .. ")")
    local have = {}
    for id, o in pairs(CC.OPEN) do
        local cls = _G[o.class]
        local ok = type(cls) == "table" and (o.sandbox and type(cls.onClickSandboxSettings) == "function" or type(cls.OnOpenPanel) == "function")
        have[#have + 1] = id .. "=" .. tostring(ok)
        check(ok, "2: the debug window for " .. id .. " (" .. o.class .. ") is in this build")
    end
    say("NOTE openers: " .. table.concat(have, " "))
end)
-- ===== 3. a pick opens Cheats
step(5, function()
    local w = win()
    w:cmdPick(CC.byName.godmode)
end)
step(15, function()
    shot("cheats")
    local open = ISAdminPowerUI and ISAdminPowerUI.instance and ISAdminPowerUI.instance:isVisible()
    check(open == true, "3: picking /godmode opened the Cheats window")
    shutCheats()
    local w = win()
    check(w.csel == "godmode", "3: /godmode picked, its detail shown")
end)
-- ===== 4. the search
step(10, function()
    local w = win()
    w.cq:setText("weather")
end)
step(10, function()
    local w = win()
    shot("search")
    check(w._cShown ~= nil and w._cShown >= 1 and w._cShown < 10, "4: \"weather\" narrows the list (" .. tostring(w._cShown) .. ")")
    w.cq:setText("ban")
end)
step(10, function()
    local w = win()
    check(w._cShown ~= nil and w._cShown >= 6, "4: \"ban\" finds the ban commands (" .. tostring(w._cShown) .. ")")
    w.cq:setText("")
end)
-- ===== 5. the controller
step(10, function()
    DC.qaJoy = true
    local w = win()
    w.zone, w.stripFocus = "strip", 2
    w:onJoypadDirRight()
    check(w.zone == "page", "5: right from the strip, the list")
    w:onJoypadDirDown(); w:onJoypadDirDown()
end)
step(10, function()
    shot("pad_list")
    local w = win()
    check(w.csel ~= nil, "5: down onto a command shows it (" .. tostring(w.csel) .. ")")
    w.cFocus = #w:_cmdItems()
    w:onJoypadDirDown()
    check(w.zone == "pband", "5: past the last row, the band (no chat line alone)")
end)
step(10, function()
    shot("pad_band")
    local w = win()
    w:onJoypadDirLeft()
    check(w.zone == "strip", "5: left from the band, the strip")
    DC.qaJoy = nil
end)

step(5, function() end)
ticker = onTick
Events.OnTick.Add(ticker)
