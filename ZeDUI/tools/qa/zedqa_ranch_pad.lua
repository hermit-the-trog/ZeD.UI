-- ZeDUI/tools/qa/zedqa_ranch_pad.lua  (Nov 5 2026, QA; f59ffdc8): the controller on the Ranch page, after zedqa_animals.lua. Pad mode
-- locked, the focus on the Totals head and on the last alert row: does the page follow? grep "ZEDQA rpd".
local function say(s) print("ZEDQA rpd " .. tostring(s)) end
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function W() return WWm.getWindow() end
add(300, function() Det.setLockedMode(Det.MODE_GAMEPAD); if not CWm.isOpen() then CWm.toggleBothPaired(0) end end)
add(2000, function() local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true; Focus.claimFocus(w) end)
local presses = 0
add(1500, function()
    local w = W()
    w._animalsScroll:setScrollPos(0)
    for _, z in ipairs(w._focusRing or {}) do for _, e in ipairs(z.elements or {}) do if e.id == "animals:disclosure:totalsExpanded" then ZONE_RPD = z.zone end end end
    Focus.focusWhere(w, ZONE_RPD, function(e) return true end)
end)
for k = 1, 34 do
    add(120, function()
        local w = W()
        local el = Focus.liveElement and Focus.liveElement(w)
        presses = k
        pcall(Focus.dispatchJoypadDir, w, "down", nil)
    end)
end
add(800, function()
    local w = W()
    local sb = w._animalsScroll
    say(string.format("%d presses of Down: scroll %.3f (0 top, 1 foot), cues %s", presses, sb.scrollPos, tostring(Focus.cuesVisible())))
    say((sb.scrollPos > 0.5 and "PASS" or "FAIL") .. " the page followed the walk down")
    pcall(function() getCore():TakeFullScreenshot("zqa_rpd_totals.png") end)
    Det.setLockedMode(nil)
    CWm.toggleBothPaired(0)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); say("DONE") end
end
Events.OnTick.Add(drive)
