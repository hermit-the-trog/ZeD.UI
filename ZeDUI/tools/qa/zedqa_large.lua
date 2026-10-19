-- ZeDUI/tools/qa/zedqa_large.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the Large text size after the audit fix. Captures
-- the Loot list and the Equip list at Small, then at Large, logs the row height
-- and the inventory's column widths, then puts the size back. grep "ZEDQA lg".
-- Screenshots zqa_lg_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA lg " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_lg_" .. n .. ".png") end) end
local function cols(tag)
    local w = cw(); local c = w and w._mainContent
    local cd = c and c._colWidths
    say(tag .. ": rowH " .. ZeD.T.rowH .. " buttonH " .. ZeD.T.buttonH .. " titleBarH " .. ZeD.T.titleBarH
        .. " | cat " .. tostring(cd and cd.cat) .. " wt " .. tostring(cd and cd.wt) .. " | equip slot col " .. tostring(ZeD.EquipmentTab.getLabelColW()))
end
local orig = ZeD.currentSize
at(2, function() if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end end)
at(20, function() tab("loot") end)
at(40, function() cols("small"); shot("small_loot") end)
at(50, function() tab("equip") end)
at(70, function() shot("small_equip") end)
at(80, function() ZeD.applyTheme(nil, nil, "large") end)
at(110, function() tab("loot") end)
at(140, function() cols("large"); shot("large_loot") end)
at(150, function() tab("equip") end)
at(180, function() shot("large_equip") end)
at(190, function() ZeD.applyTheme(nil, nil, orig); tab("loot"); say("size back to " .. tostring(orig) .. " | DONE") end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 195 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
