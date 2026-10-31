-- ZeDUI/tools/qa/zedqa_break_pad.lua  (Oct 31 2026, QA; the director: "Try to break things.")
-- The controller mashed (simulated, as suite_gamepad): on every tab of both windows, 150 random presses
-- (the D-pad four ways, A through the focused stop's own onActivate, B through the focus manager, LB / RB
-- to switch windows), one every 2 ticks, from a fixed seed so a failure can be run again. After each tab:
-- the focus must be on a stop that exists, ZeD in charge, the windows open; the stop it ended on is printed.
-- Puts back the tabs and the input mode. Shots zqa_bpad_<win>_<tab>.png. grep "ZEDQA bpad".
local D = ZeD.Input.Detector; local F = ZeD.Input.Focus
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local p = getPlayer(); local pn = p:getPlayerNum()
local function say(s) print("ZEDQA bpad " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bpad_" .. n .. ".png") end) end
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function tripped() local ok, v = pcall(function() return ZeD.Safe.on() end); return ok and v == true end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function tabsOf(strip) local out = {}; for _, z in ipairs((strip and strip._hitZones) or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = z.id:sub(5) end end; return out end
local function tab(win, key, id) local s = win and win[key]; for _, z in ipairs((s and s._hitZones) or {}) do if z.id == "tab:" .. id and win._activeTab ~= id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local function open() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(pn) end end
local seed = 1993
local function rnd(n) seed = (seed * 1103515245 + 12345) % 2147483648; return (seed % n) + 1 end
local DIRS = { "up", "down", "left", "right" }
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function mash(label, which, id)
    step(5, function()
        open(); D.setLockedMode("gamepad")
        local w = (which == "c") and CW() or WW()
        tab(w, (which == "c") and "_tabStripPanel" or "_actionTabStrip", id)
        F.claimFocus(w)
    end)
    for _ = 1, 150 do
        step(2, function()
            open()
            local w = F.getFocusedWindow() or ((which == "c") and CW() or WW())
            local k = rnd(10)
            if k <= 6 then F.dispatchJoypadDir(w, DIRS[rnd(4)])
            elseif k <= 8 then
                local e = F.getFocusedElement(w)
                if e and e.onActivate then e.onActivate(w, e) end
            elseif k == 9 then F.dispatchJoypadDown(w, Joypad.BButton)
            else F.claimFocus(rnd(2) == 1 and CW() or WW()) end
        end)
    end
    step(20, function()
        local w = F.getFocusedWindow()
        local e = w and F.getFocusedElement(w)
        local z = w and F.getFocusedZone(w)
        local ok = not tripped() and CWm.isOpen() and WWm.isOpen()
        check(ok, label .. ": ZeD in charge, both windows open; focus on " .. tostring(z and z.zone) .. " / " .. tostring(e and e.id))
        shot(label)
        -- shut what the mash opened: B a few times, then back to Loot
        for _ = 1, 4 do pcall(function() F.dispatchJoypadDown(w or CW(), Joypad.BButton) end) end
        pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
        pcall(function() ISTimedActionQueue.clear(p) end)
        if tripped() then pcall(function() ZeD.Safe.reset() end) end
    end)
end
step(5, function() if getGameSpeed() <= 0 then setGameSpeed(1) end; open() end)
step(10, function()
    local list = {}
    for _, id in ipairs(tabsOf(CW()._tabStripPanel)) do list[#list + 1] = { "c", id } end
    for _, id in ipairs(tabsOf(WW()._actionTabStrip)) do list[#list + 1] = { "w", id } end
    say("tabs " .. #list)
    ZEDQA_BPAD_TABS = list
end)
-- (the list is read when the queue is built, so the tabs are named here; a missing one is skipped by tab())
for _, t in ipairs({ { "c", "loot" }, { "c", "equip" }, { "c", "health" }, { "c", "thermal" }, { "c", "identity" }, { "c", "journal" },
        { "c", "skills" }, { "w", "loot" }, { "w", "craft" }, { "w", "build" }, { "w", "furniture" }, { "w", "maps" },
        { "w", "forage" }, { "w", "animals" }, { "w", "vehicle" } }) do
    mash(t[1] .. "_" .. t[2], t[1], t[2])
end
step(5, function()
    D.setLockedMode(nil); open()
    tab(CW(), "_tabStripPanel", "loot"); tab(WW(), "_actionTabStrip", "loot")
end)
step(20, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
