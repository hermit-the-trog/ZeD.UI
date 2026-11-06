-- ZeDUI/tools/qa/zedqa_bar_step.lua  (Nov 5 2026, QA; b8253d43): an in-game bar's arrow moves about one row (24u) and the track
-- about a page. The World / Character list's own ZeD_ScrollbarState, pressed the way its window does. grep "ZEDQA bst".
local function say(s) print("ZEDQA bst " .. tostring(s)) end
local CWm = ZeD_CharacterWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function()
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    local p = getPlayer()
    for k = 1, 60 do p:getInventory():AddItem("Base.Nails"); p:getInventory():AddItem("Base.Apple"); p:getInventory():AddItem("Base.Hammer") end
end)
add(2500, function()
    local w = CWm.getWindow()
    local c = w._mainContent
    local sb = (c and c._colStates and c._colStates[1] and c._colStates[1].scroll) or (c and c._scroll)
    if not sb then say("ERR no bar"); say("DONE"); return end
    if sb.barSizeRatio >= 1 then say("the list fits: " .. tostring(sb.barSizeRatio)) end
    local range = sb:scrollRange()
    sb:setScrollPos(0)
    local px = ZeD.T.px(24)
    sb:handleMouseDown(sb.height - math.floor(sb.arrowH / 2)); sb:handleMouseUp()
    local a = sb.scrollPos * range
    say(string.format("arrow: %.1f px, a row is %d px, the bar's height %d, range %.0f", a, px, sb.height, range))
    say((math.abs(a - px) <= 2 and "PASS" or "FAIL") .. " an arrow moves one row")
    sb:setScrollPos(0)
    sb:handleMouseDown(sb:getThumbY() + sb:getThumbHeight() + 2); sb:handleMouseUp()
    local b = sb.scrollPos * range
    say(string.format("track: %.1f px against 90%% of the view %.0f", b, sb.height * 0.9))
    say((math.abs(b - sb.height * 0.9) <= 3 and "PASS" or "FAIL") .. " the track moves about a page")
    sb:setScrollPos(0)
end)
add(500, function()
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
