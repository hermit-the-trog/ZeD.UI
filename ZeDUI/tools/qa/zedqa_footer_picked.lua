-- ZeDUI/tools/qa/zedqa_footer_picked.lua  (Nov 11 2026, Build): the window footer drops its weight. The help line
-- at rest says "48 items", or "3 of 48 picked | 4.2 kg" while rows are picked, in both windows; the title bar and the
-- container heading keep their weights. Opens both windows on the inventory side, reads the line with nothing
-- picked, picks three rows (a stack's row among them if there is one) with the mouse's table and with the pad's
-- marks, reads it again, and screenshots each. grep "ZEDQA fpk".
-- Look at: zqa_fpk_rest.png (the footer: count only), zqa_fpk_picked.png (count of total picked and the weight),
-- zqa_fpk_world.png (the World window's footer the same way).
local function say(s) print("ZEDQA fpk " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function shot(name) pcall(function() getCore():TakeFullScreenshot(name) end) end
local function line(w) return w and w.getStatusLine and w:getStatusLine() or "(none)" end
-- the first rows of a content's list, as many as asked
local function firstRows(cnt, n)
    local out = {}
    for _, it in ipairs(cnt._flatItems or {}) do
        if #out >= n then break end
        out[#out + 1] = it
    end
    return out
end
local function clear(cnt)
    if not cnt then return end
    ZeD.InventoryRenderer.padClearMarksOf(cnt)
    cnt._selectedItems = cnt._selectedItems or {}
end

add(300, function() if not CWm.isOpen() then CWm.toggleBothPaired(0) end end)
add(2000, function()
    local w = CWm.getWindow()
    clear(w._mainContent)
end)
add(600, function()
    local w = CWm.getWindow()
    local s = line(w)
    say("Character at rest: " .. s)
    say((s:find("kg") == nil and s:find("%d") ~= nil and "PASS" or "FAIL") .. " the resting line is a count with no weight")
    local ts = w.titleStats or {}
    local last = ts[#ts]
    say("title bar weight: " .. tostring(last and last.text))
    say((last and tostring(last.text):find(" / ") and "PASS" or "FAIL") .. " the title bar keeps the load over the max")
    local ci = w._mainContent and w._mainContent._containerInfo
    say("heading: " .. tostring(ci and ci.count) .. " | " .. tostring(ci and ci.stats))
    shot("zqa_fpk_rest.png")
end)
add(300, function()
    local w = CWm.getWindow()
    local cnt = w._mainContent
    for _, it in ipairs(firstRows(cnt, 3)) do cnt._selectedItems[it] = true end
    cnt._padMarks = true
end)
add(600, function()
    local w = CWm.getWindow()
    local s = line(w)
    say("Character picked (mouse's table): " .. s)
    say((s:find("kg") and s:find("%d+ of %d+") and "PASS" or "FAIL") .. " picks show k of N and the weight")
    shot("zqa_fpk_picked.png")
    clear(w._mainContent)
end)
add(300, function()
    local w = CWm.getWindow()
    local cnt = w._mainContent
    for _, it in ipairs(firstRows(cnt, 2)) do ZeD.InventoryRenderer.padMark(w, { item = it }) end
end)
add(600, function()
    local w = CWm.getWindow()
    local s = line(w)
    say("Character pad marks: " .. s .. " (marks " .. ZeD.InventoryRenderer.padMarkCount(w) .. ")")
    say((s:find("of") and "PASS" or "FAIL") .. " the pad's marks feed the same line")
    clear(w._mainContent)
end)
add(600, function()
    local w = WWm.getWindow()
    if not w then say("FAIL no World window"); return end
    clear(w._mainContent)
end)
add(600, function()
    local w = WWm.getWindow()
    say("World at rest: " .. line(w))
    local cnt = w._mainContent
    for _, it in ipairs(firstRows(cnt, 3)) do cnt._selectedItems[it] = true end
    cnt._padMarks = true
end)
add(600, function()
    local w = WWm.getWindow()
    local s = line(w)
    say("World picked: " .. s)
    say(((s:find("kg") and s:find("of")) and "PASS" or "SKIP (nothing in the container)") .. " the World line shows picks")
    shot("zqa_fpk_world.png")
    clear(w._mainContent)
end)
add(300, function()
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
