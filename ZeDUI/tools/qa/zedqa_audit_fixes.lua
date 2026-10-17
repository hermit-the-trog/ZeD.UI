-- ZeDUI/tools/qa/zedqa_audit_fixes.lua  (Oct 17 2026)
-- In game on the ZeD-QA save: the code-audit fixes the game can show without a
-- death. (1) A tab that throws logs once, not every frame, and the tab draws
-- again once it stops throwing. (2) The Equip tab's item card hides when another
-- tab shows. (3) The item card closes once its item leaves the character.
-- (4) The title-bar weight is the character's own load. grep "ZEDQA af".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA af " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local origPapers, apple
at(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
-- (1) a throwing tab
at(10, function() tab("journal"); cw()._journalSubTab = 3 end)
at(20, function()
    origPapers = ZeD.JournalReaders.renderPapers
    ZeD.JournalReaders.renderPapers = function() error("QA: a tab that throws") end
end)
at(80, function() ZeD.JournalReaders.renderPapers = origPapers end)
at(100, function()
    say("tab draws again: zones " .. #(cw()._jrZones or {}))
end)
-- (2) the Equip card on another tab
at(110, function() tab("equip") end)
at(140, function()
    local w = cw()
    local z = w._equipSlotZones and w._equipSlotZones[1]
    say("equip slots " .. tostring(w._equipSlotZones and #w._equipSlotZones))
    if z then w._equipSelected = z.type end
end)
at(170, function()
    local d = cw()._drawerPanel
    say("equip card shown on Equip: " .. tostring(d._equipCard and d._equipCard:isVisible()))
    tab("journal")
end)
at(200, function()
    local d = cw()._drawerPanel
    say("equip card on Journal (expect false): " .. tostring(d._equipCard and d._equipCard:isVisible()))
    cw()._equipSelected = nil
end)
-- (3) the item card outlives its item
at(210, function()
    tab("loot")
    apple = p:getInventory():AddItem("Base.Apple")
end)
at(240, function()
    local w = cw(); local c = w._contentPanel
    c._selectedItems = c._selectedItems or {}
    for k in pairs(c._selectedItems) do c._selectedItems[k] = nil end
    c._selectedItems[apple] = true
    w._updateDrawer(c)
    say("card item set: " .. tostring(w._drawerItem == apple) .. " mode " .. tostring(w._drawerMode))
end)
at(260, function() p:getInventory():Remove(apple) end)
at(300, function()
    local w = cw()
    say("after the apple left: drawer item " .. tostring(w._drawerItem) .. " mode " .. tostring(w._drawerMode) .. " (expect nil, nil)")
    -- (4) the title-bar weight
    say("weight " .. tostring(w._contentPanel and math.floor(p:getInventory():getCapacityWeight() * 100 + 0.5) / 100))
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 305 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
