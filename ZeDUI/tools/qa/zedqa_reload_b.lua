-- ZeDUI/tools/qa/zedqa_reload_b.lua  (Nov 2 2026, QA; the beta checklist, old item 10: save and reload, second half)
-- Run by reload_run.ps1 in a fresh game after zedqa_reload_a.lua. Reads Lua/zedqa_reload_expect.txt and checks that
-- the two settings, the Character window's place and tab, and the loadout came back. Then puts the settings back and
-- removes the loadout. grep "ZEDQA rlb".
local function say(s) print("ZEDQA rlb " .. tostring(s)) end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local p = getPlayer()
local S = ZeD.Settings
local CW = ZeD_CharacterWindow
local exp = {}
local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    local r = getFileReader("zedqa_reload_expect.txt", false)
    if not check(r ~= nil, "the first half's notes are there") then return end
    local l = r:readLine()
    while l do local k, v = l:match("^(%w+)=(.*)$"); if k then exp[k] = v end; l = r:readLine() end
    r:close()
    check(tostring(S.watchPlaceOption:getValue()) == exp.watchPlace, "the watch's place came back (" .. tostring(S.watchPlaceOption:getValue()) .. ", set " .. tostring(exp.watchPlace) .. ")")
    check(tostring(S.equipViewOption:getValue()) == exp.equipView, "the Equip view came back (" .. tostring(S.equipViewOption:getValue()) .. ", set " .. tostring(exp.equipView) .. ")")
    if not CW.isOpen() then CW.toggleBothPaired(0) end
end)
step(40, function()
    local w = CW.getWindow()
    local x, y = math.floor(w:getX()), math.floor(w:getY())
    check(math.abs(x - tonumber(exp.cx or -999)) <= 2 and math.abs(y - tonumber(exp.cy or -999)) <= 2,
        "the Character window opens where it was left (" .. x .. "," .. y .. ", left at " .. tostring(exp.cx) .. "," .. tostring(exp.cy) .. ")")
    check(tostring(w._activeTab) == exp.tab, "the Character window opens on the tab it was left on (" .. tostring(w._activeTab) .. ", left on " .. tostring(exp.tab) .. ")")
    local L = ZeD.Lists
    local got = L.get(p, tonumber(exp.listId))
    check(got ~= nil and got.name == exp.listName, "the loadout came back (" .. tostring(got and got.name) .. ")")
    check(got ~= nil and got.lines ~= nil and #got.lines == 1, "the loadout kept its line (" .. tostring(got and got.lines and #got.lines) .. ")")
    pcall(function() getCore():TakeFullScreenshot("zqa_rlb_reloaded.png") end)
end)
step(10, function()
    -- put back
    pcall(function() S.watchPlaceOption:setValue(tonumber(exp.watchPlaceWas)); S.equipViewOption:setValue(tonumber(exp.equipViewWas)); PZAPI.ModOptions:save() end)
    pcall(function()
        local md = p:getModData().ZeD_Lists
        for i = #(md and md.lists or {}), 1, -1 do if md.lists[i].id == tonumber(exp.listId) then table.remove(md.lists, i) end end
    end)
    local w = CW.getWindow()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:loot" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    say("put back: the two settings, the loadout removed")
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
end)
step(20, function() say("DONE") end)

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
