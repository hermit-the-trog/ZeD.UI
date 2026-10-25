-- ZeDUI/tools/qa/zedqa_loot_tabs.lua  (Oct 25 2026)
-- Both windows back on their Loot tab (the Character window's tab drawer shut), the
-- state the controller and curtain tests start from. Tests that open a tab drawer
-- (the doll, the curtain) leave it open and the save keeps it, so a run that puts
-- one of them before zedqa_world_pad_take.lua fails that test's first moves.
-- grep "ZEDQA lt".
local function say(s) print("ZEDQA lt " .. tostring(s)) end
local function goTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end
local n = 0
local function tick()
    n = n + 1
    if n == 5 then
        local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        if c then goTab(c, c._tabStripPanel, "loot") end
        if w then goTab(w, w._actionTabStrip, "loot") end
    elseif n == 45 then
        Events.OnTick.Remove(tick)
        local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        say("Character " .. tostring(c and c._activeTab) .. " drawer " .. tostring(c and c._drawerOpen) .. " | World " .. tostring(w and w._activeTab) .. " drawer " .. tostring(w and w._drawerOpen))
        say("DONE")
    end
end
Events.OnTick.Add(tick)
say("start")
