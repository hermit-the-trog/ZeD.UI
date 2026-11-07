-- ZeDUI/tools/qa/zedqa_ranch_long.lua  (Nov 6 2026, QA): the beta 6a regression ran on a save holding a pen. Two questions on real data: on a long Ranch page does Down reach the
-- last stop and does the wheel reach the foot of the page, with no limit on either (the regression stops at 45 presses and 60 ticks); and what on the character's square
-- has no sprite name (the floor menu's error in zedqa_ctx_icons.lua). grep "ZEDQA rlg". Pictures zqa_rlg_*.png.
local function say(s) print("ZEDQA rlg " .. tostring(s)) end
local AT, AP = ZeD.AnimalsTab, ZeD.AnimalsAlertPoller
local Focus = ZeD.Input.Focus
local function W() return ZeD_WorldWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rlg_" .. n .. ".png") end) end
local p = getPlayer()
local function scan()
    local cell, bad, seen = getCell(), 0, 0
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    say("player " .. px .. "," .. py .. "," .. pz)
    for dx = -12, 12 do for dy = -12, 12 do
        local sq = cell:getGridSquare(px + dx, py + dy, pz)
        local objs = sq and sq:getObjects()
        for i = 0, (objs and objs:size() or 0) - 1 do
            local o = objs:get(i)
            seen = seen + 1
            local spr = o:getSprite()
            local nm = spr and spr:getName()
            if not nm then
                bad = bad + 1
                say("no sprite name at " .. (px + dx) .. "," .. (py + dy) .. " class " .. tostring(o:getObjectName()) .. " sprite " .. tostring(spr) .. " item " .. tostring(o.getItem and o:getItem()))
            end
        end
    end end
    say("scanned " .. seen .. " objects, " .. bad .. " with no sprite name")
end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local presses, lastId, same, walking = 0, nil, 0, false
step(30, function()
    scan()
    AP.refreshCache()
    say("animals " .. #AP.getAllAnimals() .. ", zones " .. #AP.getZoneList() .. ", alerts " .. #AP.getAlerts())
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
step(90, function() local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true; AT.switchSubmode(w, "ranch") end)
step(30, function()
    local w = W()
    Focus.claimFocus(w)
    local first
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == "worldTabContent" and z.focusable then
            say("zone " .. z.zone .. " stops " .. #(z.elements or {}))
            for _, e in ipairs(z.elements or {}) do first = first or ((not e.isDisclosure) and e or nil) end
        end
    end
    Focus.focusWhere(w, "worldTabContent", function(e) return e == first end)
    lastId = first and first.id
    local sb = w._animalsScroll
    say("first " .. tostring(lastId) .. " bar visible " .. tostring(sb and sb.visible) .. " range " .. tostring(sb and sb:scrollRange()))
end)
local function walk()
    local w = Focus.getFocusedWindow()
    local z, e = w and Focus.getFocusedZone(w), w and Focus.getFocusedElement(w)
    if presses >= 400 or not z or z.zone ~= "worldTabContent" or same >= 2 then
        local ww = W()
        local sb = ww._animalsScroll
        say("Down stopped after " .. presses .. " presses on " .. tostring(lastId) .. " now in " .. tostring(z and z.zone) .. ", scroll " .. tostring(sb and sb.scrollPos))
        Focus.focusWhere(ww, "worldTabContent", function(x) return x.id == lastId end)

        return
    end
    if e and e.id == lastId then same = same + 1 else same = 0 end
    if e then lastId = e.id end
    presses = presses + 1
    Focus.dispatchJoypadDir(w, "down")
    return true
end
step(3, function() end)
local function afterWalk()
    step(30, function() shot("01_after_down") end)
    step(20, function()
        local w = W(); local sb = w._animalsScroll
        sb:setScrollPos(0)
        local dp = w._drawerPanel
        local ticks = 0
        while sb.scrollPos < 0.9999 and ticks < 600 do dp:onMouseWheel(1); ticks = ticks + 1 end
        say("wheel: " .. ticks .. " ticks to the foot, scroll " .. tostring(sb.scrollPos) .. " page range " .. tostring(sb:scrollRange()))
    end)
    step(30, function() shot("02_foot") end)
    step(5, function()
        local w = W(); w._animalsScroll:setScrollPos(0); w._activeTab = "loot"
        say("DONE")
    end)
end
local function tick()
    if wait > 0 then wait = wait - 1; return end
    if walking then
        if walk() then wait = 3; return end
        walking = false
        afterWalk()
        wait = 15
        return
    end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    local ok, er = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(er)) end
    wait = s.n
    if qi == 4 then walking = true end
end
say("start")
Events.OnTick.Add(tick)
