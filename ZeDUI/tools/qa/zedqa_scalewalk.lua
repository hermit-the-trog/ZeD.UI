-- ZeD QA S124 phase 2: open the pair, walk the main tabs of both windows at the natural root and at a forced 1.0, capture each
local Sc = ZeD.Scale
local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow()
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function tabsOf(strip) local out = {}; for _, z in ipairs(strip._hitZones or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = { id = z.id:sub(5), x = z.x + math.floor(z.w / 2), y = z.y + math.floor(z.h / 2) } end end; return out end
local t = 5
at(t, function() if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end; cw = ZeD_CharacterWindow.getWindow(); if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end end)
t = t + 40
for _, pass in ipairs({ { nil, "200" }, { 1.0, "100" } }) do
    local ov, tag = pass[1], pass[2]
    at(t, function() Sc.override = ov; Sc.refresh(); ZeD.applyTheme() end); t = t + 30
    for _, w in ipairs({ { "char", function() return ZeD_CharacterWindow.getWindow() end, function(win) return win._tabStripPanel end }, { "world", function() return ZeD_WorldWindow.getWindow() end, function(win) return win._actionTabStrip end } }) do
        local label, getWin, getStrip = w[1], w[2], w[3]
        at(t, function()
            local win = getWin(); local strip = win and getStrip(win); if not strip then print("ZEDQA sw " .. label .. " no strip") return end
            local tabs = tabsOf(strip); local ids = {}; for _, tb in ipairs(tabs) do ids[#ids + 1] = tb.id end
            print("ZEDQA sw " .. label .. " tabs " .. table.concat(ids, ","))
            win._zedqaTabs = tabs
        end); t = t + 5
        for k = 1, 8 do
            at(t, function() local win = getWin(); local tb = win and win._zedqaTabs and win._zedqaTabs[k]; if tb then getStrip(win):onMouseDown(tb.x, tb.y) end end)
            at(t + 25, function() local win = getWin(); local tb = win and win._zedqaTabs and win._zedqaTabs[k]; if tb then pcall(function() getCore():TakeFullScreenshot("zedqa_sw_" .. tag .. "_" .. label .. "_" .. tb.id .. ".png") end); print("ZEDQA sw shot " .. tag .. " " .. label .. " " .. tb.id .. " active=" .. tostring(win._activeTab) .. " win=" .. tostring(win:getX()) .. "," .. tostring(win:getY()) .. " " .. tostring(win:getWidth()) .. "x" .. tostring(win:getHeight())) end end)
            t = t + 35
        end
        at(t, function() local win = getWin(); local tb = win and win._zedqaTabs and win._zedqaTabs[1]; if tb then getStrip(win):onMouseDown(tb.x, tb.y) end end); t = t + 10
    end
end
at(t, function() Sc.override = nil; Sc.refresh(); ZeD.applyTheme(); print("ZEDQA sw done root=" .. tostring(Sc.root())) end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA sw armed")
