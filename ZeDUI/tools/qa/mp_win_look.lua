-- ZeDUI/tools/qa/mp_win_look.lua  (Nov 6 2026, QA): on the local server, on the final code: do the windows open, by the tab call, with and without the pad stood in. grep "ZEDQA mwl".
local function say(s) print("ZEDQA mwl " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local p = getPlayer()
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function state(tag)
    local c, w = CWm.getWindow(), WWm.getWindow()
    say(tag .. ": alive " .. tostring(p:isAlive()) .. ", health " .. tostring(p:getHealth()) .. ", at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY())
        .. ", Character window " .. tostring(c ~= nil) .. (c and (" visible " .. tostring(c:isVisible()) .. " tab " .. tostring(c._activeTab)) or "")
        .. ", World window " .. tostring(w ~= nil) .. ", isOpen " .. tostring(CWm.isOpen and CWm.isOpen()))
end
add(1000, function() state("start") end)
add(500, function() CWm.openTab(0, "server") end)
add(2000, function() state("after openTab") end)
add(500, function() ZeD.Input.Detector.setLockedMode(ZeD.Input.Detector.MODE_GAMEPAD) end)
add(2000, function() state("pad mode") end)
add(500, function() ZeD.Input.Detector.setLockedMode(nil) end)
add(1000, function() state("back"); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
