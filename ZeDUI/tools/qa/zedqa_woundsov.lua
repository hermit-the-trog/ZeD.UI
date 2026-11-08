-- ZeDUI/tools/qa/zedqa_woundsov.lua  (Nov 7 2026, QA): Wounds Overhaul (3775026731) with ZeD. A Workshop comment: "I can't
-- even open my inventory", no errors. Checks, with the mod on:
--   * the inventory key (the game's key event, as a press sends it) opens and shuts ZeD's pair;
--   * whether the game's own Character Info window shows (ZeD hides it; Wounds Overhaul puts its examination tab there);
--   * a cut on the left forearm: what ZeD's Health tab says about it, and what the part's treatment menu (the one ZeD
--     opens through ISHealthPanel.doBodyPartContextMenu) offers: Wounds Overhaul holds treatment back until the part
--     is examined ("Something is wrong here."), and the examination lives in its own tab.
-- Puts the wound back. grep "ZEDQA wo".
local function say(s) print("ZEDQA wo " .. tostring(s)) end
local p = getPlayer()
local CW = ZeD_CharacterWindow
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local key = getCore():getKey("Toggle Inventory")
local part = p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_L)
local function press()
    pcall(triggerEvent, "OnKeyStartPressed", key)
    pcall(triggerEvent, "OnKeyPressed", key)
end
local function keepDown()
    local w = CW.getWindow()
    if w then w._autoShaded = false; if w.windowShaded then w:setWindowShaded(false) end; w._outSince = getTimestampMs() + 600000 end
end
say("Wounds Overhaul loaded: " .. tostring(type(Wounds) == "table") .. "; examine mode " .. tostring(Wounds and Wounds.examineMode and select(2, pcall(Wounds.examineMode))))
at(5, function() if CW.isOpen() then CW.toggleBothPaired(0) end end)
at(15, function() say("before the key: open " .. tostring(CW.isOpen())); press() end)
at(35, function()
    say((CW.isOpen() and "PASS" or "FAIL") .. " the inventory key opens ZeD's windows (open " .. tostring(CW.isOpen()) .. ")")
    press()
end)
at(55, function()
    say((not CW.isOpen() and "PASS" or "FAIL") .. " a second press shuts them")
    local ok, ci = pcall(getPlayerInfoPanel, 0)
    say("the game's Character Info window: " .. tostring(ok and ci and ci:getIsVisible()) .. ", its tabs: " .. (function()
        local out = {}
        for _, v in ipairs(ok and ci and ci.panel and ci.panel.viewList or {}) do out[#out + 1] = tostring(v.name) end
        return table.concat(out, ", ")
    end)())
    part:setCut(true); part:setCutTime(20)
    press()
end)
at(75, function()
    keepDown()
    CW.openTab(0, "health")
end)
at(110, function()
    keepDown()
    local held = Wounds and Wounds.body and Wounds.body.needsExamFirst and select(2, pcall(Wounds.body.needsExamFirst, part))
    say("the cut part needs an examination first (Wounds Overhaul): " .. tostring(held))
    -- (ZeD's own click on the figure's part: the path a player takes)
    local ok, e = pcall(ZeD.HealthTab._onPartClicked, CW.getWindow(), "Left Forearm", nil, 10, 10)
    local m = getPlayerContextMenu(0)
    local names = {}
    for _, o in ipairs(m and m.options or {}) do names[#names + 1] = tostring(o.name) end
    say("the part's menu (ok " .. tostring(ok) .. (ok and "" or (", " .. tostring(e))) .. "): " .. table.concat(names, " | "))
    pcall(function() getCore():TakeFullScreenshot("zqa_wo_health.png") end)
end)
at(130, function()
    local m = getPlayerContextMenu(0); if m then pcall(function() m:hideAndChildren() end) end
    part:setCut(false); part:setCutTime(0)
    if CW.isOpen() then CW.toggleBothPaired(0) end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR step " .. s.n .. ": " .. tostring(e)) end end
    end
    if tick > 135 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
