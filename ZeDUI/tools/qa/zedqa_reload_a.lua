-- ZeDUI/tools/qa/zedqa_reload_a.lua  (Nov 2 2026, QA; the beta checklist, old item 10: save and reload, first half)
-- Run by reload_run.ps1. Changes what a player would expect to find again after a quit: two ZeD settings (the watch's
-- place, the Equip view) saved the way the options screen saves them, the Character window moved and left on Skills,
-- and a new loadout with one line. Writes what it set to Lua/zedqa_reload_expect.txt and a copy of the saved
-- ModOptions.ini to Lua/zedqa_reload_ini.txt (the runner puts the director's file back after each run; the wrapper
-- carries this copy into the second run). The runner's quit to the main menu saves the game. grep "ZEDQA rla".
local function say(s) print("ZEDQA rla " .. tostring(s)) end
local p = getPlayer()
local S = ZeD.Settings
local CW = ZeD_CharacterWindow
local exp = {}
local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end
end)
step(30, function()
    -- the settings: each to its other value
    local wp = S.watchPlaceOption:getValue(); local wpTo = (wp == 1) and 2 or 1
    local ev = S.equipViewOption:getValue(); local evTo = (ev == 1) and 2 or 1
    S.watchPlaceOption:setValue(wpTo); S.equipViewOption:setValue(evTo)
    PZAPI.ModOptions:save()
    exp.watchPlaceWas, exp.watchPlace = wp, wpTo
    exp.equipViewWas, exp.equipView = ev, evTo
    say("settings: watch place " .. wp .. " -> " .. wpTo .. ", Equip view " .. ev .. " -> " .. evTo)
    -- the window: moved, on Skills
    local w = CW.getWindow()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:skills" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    w:setX(w:getX() + 120); w:setY(w:getY() + 60)
end)
step(40, function()
    local w = CW.getWindow()
    exp.cx, exp.cy, exp.tab = math.floor(w:getX()), math.floor(w:getY()), tostring(w._activeTab)
    say("Character window at " .. exp.cx .. "," .. exp.cy .. " on " .. exp.tab)
    -- a loadout
    local L = ZeD.Lists
    local name = "QA reload " .. tostring(ZombRand(1000, 9999))
    local id = L.create(p, "loadout", name)
    if type(id) == "table" then id = id.id end
    pcall(function() L.addLine(p, id, { sec = "gear", place = "inv", rule = "any", type = "Base.Axe" }) end)
    exp.listId, exp.listName = id, name
    local got = L.get(p, id)
    say("loadout " .. tostring(id) .. " \"" .. name .. "\" made: " .. tostring(got ~= nil) .. ", lines " .. tostring(got and got.lines and #got.lines))
    -- the window's place goes into the save once a second; close and reopen to write it at once
    CW.toggleBothPaired(0)
end)
step(20, function() CW.toggleBothPaired(0) end)
step(40, function()
    local w = CW.getWindow()
    exp.cx, exp.cy, exp.tab = math.floor(w:getX()), math.floor(w:getY()), tostring(w._activeTab)
    say("reopened at " .. exp.cx .. "," .. exp.cy .. " on " .. exp.tab)
    local f = getFileWriter("zedqa_reload_expect.txt", true, false)
    for _, k in ipairs({ "watchPlaceWas", "watchPlace", "equipViewWas", "equipView", "cx", "cy", "tab", "listId", "listName" }) do
        f:write(k .. "=" .. tostring(exp[k]) .. "\r\n")
    end
    f:close()
    local r = getFileReader("ModOptions.ini", false)
    local c = getFileWriter("zedqa_reload_ini.txt", true, false)
    local n = 0
    if r then
        local l = r:readLine()
        while l do c:write(l .. "\r\n"); n = n + 1; l = r:readLine() end
        r:close()
    end
    c:close()
    say("ModOptions.ini copied: " .. n .. " lines")
end)
step(60, function() say("DONE") end)

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
