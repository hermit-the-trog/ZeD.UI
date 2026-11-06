-- ZeDUI/tools/qa/zedqa_identity2.lua  (Nov 5 2026, QA; e453aab6): the model in the same frame as a style change, the style set in a step of its own and
-- read every frame; the head staying in the bust frame with the fidgets off; the Equip doll and a tab switch. grep "ZEDQA id2".
local function say(s) print("ZEDQA id2 " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s) end
local I = ZeD.IdentityTab
local CWm = ZeD_CharacterWindow
local function W() return CWm.getWindow() end
local function tab(id) local w = W(); w._activeTab = id; w._drawerMode = "tab"; w._drawerOpen = true end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local frames, trace = 0, nil
local function watch()
    if not trace then return end
    frames = frames + 1
    local m = W()._identityModel
    local z = W()._identityPhotoZone
    trace[#trace + 1] = string.format("%d,%d", m:getX(), z and z.x or -1)
    if frames >= 8 then
        say(trace.name .. " model x / zone x by frame: " .. table.concat(trace, " "))
        local first, lastv = trace[1], trace[#trace]
        check(first == lastv, trace.name .. ": the model is in place from the first frame")
        trace = nil
    end
end
Events.OnRenderTick.Add(watch)
add(300, function() if not CWm.isOpen() then CWm.toggleBothPaired(0) end end)
add(1500, function() tab("identity"); I.qaStyle = "immersive"; W()._identityPhotoExpanded = false end)
add(2500, function() frames = 0; I.qaStyle = "simple"; trace = { name = "to Simple" } end)
add(2000, function() frames = 0; I.qaStyle = "immersive"; trace = { name = "to Immersive" } end)
add(2000, function() pcall(function() getCore():TakeFullScreenshot("zqa_id2_a.png") end) end)
add(9000, function() pcall(function() getCore():TakeFullScreenshot("zqa_id2_b.png") end) end)
add(9000, function() pcall(function() getCore():TakeFullScreenshot("zqa_id2_c.png") end) end)
add(500, function() tab("equip"); W()._equipView = "doll" end)
add(2000, function() pcall(function() getCore():TakeFullScreenshot("zqa_id2_equip.png") end); tab("identity") end)
add(2000, function() pcall(function() getCore():TakeFullScreenshot("zqa_id2_back.png") end); I.qaStyle = nil; tab("loot"); CWm.toggleBothPaired(0); Events.OnRenderTick.Remove(watch); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
