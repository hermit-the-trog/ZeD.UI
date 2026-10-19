-- ZeDUI/tools/qa/zedqa_navevents.lua  (Oct 19 2026)
-- The controller nav audit, part 2: where focus lands after things happen.
-- Simulated pad on the ZeD-QA save: a card opened and closed with B, a
-- container switched from the strip, a tab switched from the tab column, the
-- windows swapped with LB / RB and back, a focused item taken away, the map's
-- tool -> map -> back, the map unfolded and folded. grep "ZEDQA ev".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local function say(s) print("ZEDQA ev " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local function fw() return Focus.getFocusedWindow() end
local function stripTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function where(tag)
    local w = fw(); local z = w and Focus.getFocusedZone(w); local e = w and Focus.getFocusedElement(w)
    local wn = (w == cw() and "Char") or (w == ww() and "World") or tostring(w and w.title)
    say(tag .. ": " .. wn .. " " .. tostring(z and z.zone) .. ":" .. tostring(e and e.id) .. (e and e.item and (" (" .. e.item:getName() .. ")") or ""))
end
local function focusEl(w, zoneName, pred)
    for zi, z in ipairs(w._focusRing or {}) do
        if z.zone == zoneName then
            for ei, e in ipairs(z.elements or {}) do
                if pred(e, ei) then w._focusIdx = zi; z.focusedElementIdx = ei; if e.onFocus then e.onFocus(w, e) end; return e end
            end
        end
    end
end
local function dir(d) Focus.dispatchJoypadDir(fw(), d) end
local function B() Focus.dispatchJoypadDown(fw(), Joypad.BButton) end
local hammer, nail
at(2, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    hammer = p:getInventory():AddItem("Base.Hammer")
    nail = p:getInventory():AddItem("Base.Screwdriver")
end)
at(20, function() stripTab(cw(), cw()._tabStripPanel, "loot"); stripTab(ww(), ww()._actionTabStrip, "loot"); Focus.claimFocus(cw()) end)
-- 1. a card: A on a row, Left into the card, B
at(40, function()
    local e = focusEl(cw(), "charMainInv", function(e) return e.item == hammer end)
    where("1 on the hammer row"); if e then e.onActivate(cw(), e) end
end)
at(60, function() dir("left"); where("1 Left (expect the card)") end)
at(70, function() B(); end)
at(80, function() where("1 after B (expect back on the hammer row)") end)
-- 2. Right to the strip, A on the other container, then Left
at(90, function() dir("right"); where("2 Right (expect the strip)") end)
at(95, function() dir("left"); where("2 Left (expect back on the hammer row)") end)
-- 3. Left to the tab column, Down a tab, A on it, Right
at(105, function() focusEl(cw(), "charMainInv", function(e) return e.item == nail end); where("3 on the screwdriver") end)
at(110, function() dir("left"); where("3 Left (expect the active tab)") end)
at(115, function() dir("down"); where("3 Down") end)
at(120, function() local e = Focus.getFocusedElement(fw()); where("3 A on"); if e and e.onActivate then e.onActivate(fw(), e) end end)
at(150, function() where("3 after A on the tab (expect still on it)"); dir("right"); where("3 Right (expect the tab's first control)") end)
at(160, function() dir("left"); where("3 Left (expect back on the tab)") end)
at(170, function() stripTab(cw(), cw()._tabStripPanel, "loot") end)
-- 4. RB to the World window, LB back
at(190, function() focusEl(cw(), "charMainInv", function(e) return e.item == nail end); where("4 on the screwdriver") end)
at(195, function() Focus.dispatchJoypadDown(fw(), Joypad.RBumper) end)
at(205, function() where("4 after RB (World)") end)
at(210, function() Focus.dispatchJoypadDown(fw(), Joypad.LBumper) end)
at(220, function() where("4 after LB (expect back on the screwdriver)") end)
-- 5. the focused item goes away
at(230, function() focusEl(cw(), "charMainInv", function(e) return e.item == hammer end); where("5 on the hammer") end)
at(235, function() p:getInventory():Remove(hammer) end)
at(260, function() where("5 after the hammer went (expect a neighbouring row)") end)
-- 6. the map: a tool, Down to the map, Up, Left, Right
at(270, function() Focus.claimFocus(ww()); stripTab(ww(), ww()._actionTabStrip, "maps") end)
at(310, function()
    local e = focusEl(ww(), "worldTabContent", function(e) return e.id == "map:tool:star" end)
    where("6 on the star tool"); if e then e.onActivate(ww(), e) end
end)
at(320, function() dir("down"); where("6 Down (expect the map)") end)
at(325, function() dir("up"); where("6 Up (expect back on the star tool)") end)
at(330, function() dir("down"); dir("left"); where("6 Down, Left") end)
at(335, function() dir("right"); where("6 Right (expect back on the map)") end)
at(340, function() dir("right"); where("6 Right again") end)
-- 7. unfold the map, then B
at(350, function()
    local e = focusEl(ww(), "worldTabContent", function(e) return e.id == "map:popout" end)
    where("7 on unfold"); if e then e.onActivate(ww(), e) end
end)
at(380, function() where("7 after unfold (expect the big map's window)") end)
at(390, function() B() end)
at(410, function() where("7 after B (expect the World window's map or unfold)") end)
at(420, function() local w = ww(); if w._mapPopout and ZeD.MapsTab.closePopout then ZeD.MapsTab.closePopout(w) end; w._mapActiveTool = nil; stripTab(w, w._actionTabStrip, "loot") end)
at(440, function()
    p:getInventory():Remove(nail)
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 445 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
