-- ZeDUI/tools/qa/zedqa_world_widths.lua  (Oct 25 2026)
-- Diagnostic: the World window's parts on the Crafting tab, at the natural scale and
-- after a forced 1.0 (as zedqa_scalewalk.lua does it), then both windows on Loot (the
-- tab the curtain and pad tests start from). Prints every part's x and width, the
-- drawer's animated and target widths, and the craft header's own width. grep "ZEDQA ww".
local Sc = ZeD.Scale
local function say(s) print("ZEDQA ww " .. tostring(s)) end
local function win() return ZeD_WorldWindow.getWindow() end
local function part(name, p)
    if not p then return name .. " -" end
    return string.format("%s x %d w %d y %d%s", name, p:getX(), p:getWidth(), p:getY(), p:isVisible() and "" or " (hidden)")
end
local function goTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end
local function report(tag)
    local w = win()
    if not w then say(tag .. " no World window"); return end
    local T = ZeD.T
    say(string.format("%s root %.3f scale %.3f | window x %d w %d | px(480) %d px(36) %d | effW %s maxWinW %s rolled %s tab %s",
        tag, Sc.root(), T.scale or -1, w:getX(), w:getWidth(), T.px(480), T.px(36), tostring(w._drawerEffW), tostring(w._maxWinW), tostring(w._rolled), tostring(w._activeTab)))
    local cs, ct, dr, ts, it
    for _, c in pairs(w:getChildren()) do
        local l = c._zedLabel or c.Type
        if c == w._actionTabStrip then ts = c end
        if c == w._itemDrawerPanel then it = c end
        if c == w._mainContent then ct = c end
        if c == w._drawerPanel then dr = c end
        if c == w._containerStripPanel then cs = c end
    end
    say(tag .. " " .. part("containerStrip", cs or w._containerStripPanel) .. " | " .. part("content", ct or w._mainContent) .. " | " .. part("drawer", dr or w._drawerPanel))
    say(tag .. " " .. part("actionTabStrip", ts or w._actionTabStrip) .. " | " .. part("itemDrawer", it or w._itemDrawerPanel))
    local kids = {}
    for _, c in pairs(w:getChildren()) do kids[#kids + 1] = (c._zedLabel or tostring(c.Type)) .. "@" .. c:getX() .. "+" .. c:getWidth() end
    say(tag .. " children: " .. table.concat(kids, ", "))
end

local steps, n, i = {}, 0, 1
local function at(t, f) steps[#steps + 1] = { n = t, f = f } end
at(10, function() local w = win(); if w then goTab(w, w._actionTabStrip, "craft") end end)
at(70, function() report("natural") end)
at(80, function() Sc.override = 1.0; Sc.refresh(); ZeD.applyTheme() end)
at(160, function() report("forced1.0") end)
at(170, function() Sc.override = nil; Sc.refresh(); ZeD.applyTheme() end)
at(250, function() report("back") end)
at(260, function()
    local w = win(); if w then goTab(w, w._actionTabStrip, "loot") end
    local c = ZeD_CharacterWindow.getWindow(); if c then goTab(c, c._tabStripPanel, "loot") end
end)
at(300, function()
    local w, c = win(), ZeD_CharacterWindow.getWindow()
    say("tabs now: World " .. tostring(w and w._activeTab) .. ", Character " .. tostring(c and c._activeTab))
    say("DONE")
end)
local function tick()
    n = n + 1
    while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then say("ERR " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
say("start")
