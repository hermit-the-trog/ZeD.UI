-- ZeD QA suite: simulated gamepad (no controller). D-pad via Focus.dispatchJoypadDir; A/X via element callbacks.
local D = ZeD.Input.Detector; local F = ZeD.Input.Focus
local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow()
if not cw or not ww then print("ZEDQA gp: open both windows first") return end
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local function tabClick(strip, id) for _, z in ipairs(strip._hitZones or {}) do if z.id == "tab:" .. id then strip:onMouseDown(z.x + 2, z.y + 2); return true end end; return false end
local function zone(w, name) for _, z in ipairs(w._focusRing or {}) do if z.zone == name then return z end end end
local function zm() local vm = getPlayerContextMenu and getPlayerContextMenu(0); return vm and vm._zedMenu end
local function st(w, tag)
    local z = F.getFocusedZone(w); local e = F.getFocusedElement(w); local m = zm()
    print("ZEDQA gp " .. tag .. " zone=" .. tostring(z and z.zone) .. " el=" .. tostring(e and e.id) .. " tab=" .. tostring(w._activeTab) .. " drawer=" .. tostring(w._drawerOpen) .. " item=" .. tostring(w._drawerItem and w._drawerItem:getDisplayName()) .. " ctx=" .. tostring(m ~= nil))
end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
at(5,   function() D.setLockedMode("gamepad"); tabClick(cw._tabStripPanel, "loot"); F.claimFocus(cw); st(cw, "claim") end)
at(20,  function() F.dispatchJoypadDir(cw, "down"); st(cw, "down") end)
at(30,  function() F.dispatchJoypadDir(cw, "right"); st(cw, "right") end)
at(40,  function() F.dispatchJoypadDir(cw, "left"); st(cw, "left") end)
-- stale-zone regression: Journal then Loot by strip click, then right from the inventory
at(50,  function() tabClick(cw._tabStripPanel, "journal") end)
at(110, function() tabClick(cw._tabStripPanel, "loot") end)
at(170, function() local z = zone(cw, "charTabContent"); print("ZEDQA gp loot charTabContent elements=" .. tostring(z and #(z.elements or {})) .. " (expect 0)"); F.claimFocus(cw); F.dispatchJoypadDir(cw, "right"); st(cw, "right after journal to loot (expect container strip, never jsub)") end)
-- row callbacks = what A / X fire
at(180, function() local z = zone(cw, "charMainInv"); local e = z and z.elements[2]; if e and e.onActivate then e.onActivate(cw, e) end end)
at(240, function() st(cw, "after row2 onActivate (expect card open)") end)
at(250, function() local z = zone(cw, "charMainInv"); local e = z and z.elements[3]; if e and e.onActivate then e.onActivate(cw, e) end end)
at(310, function() st(cw, "after row3 onActivate (expect live swap)") end)
at(320, function() local z = zone(cw, "charMainInv"); local e = z and z.elements[3]; if e and e.onActivate then e.onActivate(cw, e) end end)
at(380, function() st(cw, "after row3 again (expect closed)") end)
at(390, function() local z = zone(cw, "charMainInv"); local e = z and z.elements[2]; if e and e.onContextMenu then e.onContextMenu(cw, e) end end)
at(450, function() st(cw, "after row2 onContextMenu (expect ctx=true)"); local m = zm(); if m then pcall(m.onJoypadDown, m, Joypad.BButton) end end)
at(510, function() st(cw, "after ctx B (expect ctx=false)") end)
-- world window
at(520, function() F.claimFocus(ww); st(ww, "world claim") end)
at(530, function() F.dispatchJoypadDir(ww, "right"); st(ww, "world right") end)
at(540, function() tabClick(ww._actionTabStrip, "craft") end)
at(600, function() F.dispatchJoypadDir(ww, "down"); st(ww, "world craft down") end)
at(610, function() tabClick(ww._actionTabStrip, "loot") end)
at(670, function() F.dispatchJoypadDir(ww, "left"); st(ww, "world loot left (stale check)"); D.setLockedMode(nil); print("ZEDQA gp done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, err = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(err)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA gp armed")
