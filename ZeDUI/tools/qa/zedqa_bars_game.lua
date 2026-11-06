-- ZeDUI/tools/qa/zedqa_bars_game.lua  (Nov 5 2026, QA; e5ca4937, every in-game list on the real bar): the real mouse on an in-game bar, after
-- zedqa_animals.lua. Butcher's bar in the World window: the down arrow steps a row, the track pages, the up arrow steps back, and no press
-- opens the row beside it. Run by release_check.ps1 (its mouse helper). Also lists every bar the window drew. grep "ZEDQA bgm".
local function say(s) print("ZEDQA bgm " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s) end
local AT = ZeD.AnimalsTab
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function W() return WWm.getWindow() end
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local SB
local function st() return AT.getButcherState(W()) end
add(300, function() if not CWm.isOpen() then CWm.toggleBothPaired(0) end end)
add(2000, function()
    local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true
    AT.switchSubmode(w, "butcher")
end)
add(7000, function()
    local w = W()
    local keys = {}
    for k in pairs(w._zedBars or {}) do keys[#keys + 1] = k end
    say("bars on the window: " .. table.concat(keys, ", "))
    SB = w._zedBars and w._zedBars["an:butcher"]
    if not SB then say("ERR no Butcher bar"); return end
    local bs = w._animalsButcherScroll
    say(string.format("bar at %d,%d %dx%d, arrows %d, needs scroll %s", SB.x, SB.y, SB.width, SB.height, SB.arrowH, tostring(bs and bs.needsScroll)))
    -- where the bar's panel sits: the panel that drew it reports the mouse in its own frame
    local panel = w._drawerPanel
    local ax, ay = panel:getAbsoluteX(), panel:getAbsoluteY()
    AX, AY = math.floor(ax + SB.x + SB.width / 2), ay + SB.y
    say("screen place " .. AX .. "," .. AY)
    local orig = SB.handleMouseDown
    SB.handleMouseDown = function(self, ly)
        say("press reached the bar at " .. tostring(ly) .. " of " .. tostring(self.height) .. ", down arrow from " .. tostring(self.arrowH + self:getTrackHeight()) .. ", thumb " .. tostring(self:getThumbY()) .. " + " .. tostring(self:getThumbHeight()))
        return orig(self, ly)
    end
    S0 = st().scrollY
    VIEW0 = AT.getState(w).view
    req("left " .. AX .. " " .. (AY + SB.height - math.floor(SB.arrowH / 2)))
end)
add(7000, function()
    local a = st().scrollY
    say("after the down arrow: " .. tostring(S0) .. " to " .. tostring(a))
    check(a > S0, "the real mouse on the down arrow moves the list")
    check(AT.getState(W()).view == VIEW0, "the press opens nothing")
    S1 = a
    req("left " .. AX .. " " .. (AY + SB.height - SB.arrowH - 6))
end)
add(7000, function()
    local a = st().scrollY
    say("after the track: " .. tostring(S1) .. " to " .. tostring(a))
    check(a > S1, "a press on the track pages")
    S2 = a
    req("left " .. AX .. " " .. math.floor(AY + SB.arrowH / 2))
end)
add(7000, function()
    local a = st().scrollY
    say("after the up arrow: " .. tostring(S2) .. " to " .. tostring(a))
    check(a < S2, "the up arrow steps back")
    pcall(function() getCore():TakeFullScreenshot("zqa_bgm_butcher.png") end)
    AT.switchSubmode(W(), "ranch")
    CWm.toggleBothPaired(0)
    say("DONE")
end)
local function drive()
    local st_ = plan[i]
    if not st_ then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st_.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st_.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); say("DONE") end
end
Events.OnTick.Add(drive)
