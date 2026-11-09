-- ZeDUI/tools/qa/zedqa_b9a_8.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 8): Pin and Unpin have ZeD's pin icon in the
-- right-click menu (they drew "PI" / "UN"). The director's sequence with the mouse: a real right-click on a bottle in
-- the Character list opens its menu: "Pin to title bar" has the pin, the drawing the title bar's pin boxes use; pinned,
-- a second right-click shows "Unpin from title bar" with the same pin. Every other option in both menus is listed with
-- its icon, and any without one is named (an action added in beta 9 would show there). Pins are put back.
-- The REAL mouse (release_check_mouse.ps1: right x y), so run it with batch_b9a.ps1. grep "ZEDQA b9a8".
-- Screen size is read, never set. Pictures zqa_b9a8_<w>x<h>_<n>.png.
local TAG = "b9a8"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, s) if ok then pass = pass + 1 else fail = fail + 1 end; say((ok and "PASS " or "FAIL ") .. s); return ok end
if ZEDQA_HOME then ZEDQA_HOME(TAG) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
say("screen " .. sw .. "x" .. sh)
local CWm = ZeD_CharacterWindow
local function CW() return CWm.getWindow() end
local R = ZeD.ContextMenu and ZeD.ContextMenu.Registry
-- The real-mouse helper (release_check_mouse.ps1) takes ONE request at a time: it deletes zedqa_click.txt, acts
-- (down, move and up 250 ms each) and writes zedqa_click_done.txt. So, as zedqa_dual_pin's req and mouse(): clear the
-- done file, write the request, and the plan waits for "done" before it counts the next step's delay (drive below).
-- Back-to-back requests without the wait overwrote each other: drags never started and clicks were lost.
local pending, pendAt = nil, 0
local function req(s)
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(s); f:close() end)
    pending, pendAt = s, getTimestampMs()
end
local function done()
    local r = getFileReader("zedqa_click_done.txt", false)
    local l = r and r:readLine()
    if r then r:close() end
    return l ~= nil and l:find("done", 1, true) ~= nil
end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- a step that runs once cond() is true, or after max ms (a timed action ending, a state settling)
local function addWhen(max, cond, fn) plan[#plan + 1] = { ms = max, cond = cond, fn = fn } end
local keepTab, keepPinsMd
local function rowOf(win, fullType)
    local c = win._mainContent
    for _, it in ipairs(c and c._flatItems or {}) do
        if it:getFullType() == fullType then
            local y = c._itemRenderYMap and c._itemRenderYMap[it]
            if not y then return nil end
            local x = (c._itemRenderXMap and c._itemRenderXMap[it]) or 0
            return it, math.floor(c:getAbsoluteX() + x + 170), math.floor(c:getAbsoluteY() + y + ZeD.T.rowH / 2)
        end
    end
end
local function hasOption(name)
    local v = getPlayerContextMenu(0)
    for _, o in ipairs(v and v.options or {}) do if tostring(o.name) == name then return true end end
    return false
end
-- the open menu's options: each one's icon (the registry's answer for its name), the pin ones checked
local function readMenu(label, want)
    local v = getPlayerContextMenu(0)
    local found = false
    for _, o in ipairs(v and v.options or {}) do
        local name = tostring(o.name)
        local tex, id = nil, nil
        if R and R.resolveIconForName then tex, id = R.resolveIconForName(name) end
        local has = tex ~= nil or o.iconTexture ~= nil or o.itemForTexture ~= nil
        say(label .. " option: " .. name .. " | icon " .. tostring(id or (has and "texture") or "NONE"))
        if name == want then
            found = true
            check(id == "pin", label .. ": \"" .. want .. "\" has ZeD's pin icon (" .. tostring(id) .. ")")
        end
    end
    check(found, label .. ": the menu has \"" .. want .. "\"")
end

add(500, function()
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTab = CW()._activeTab
    local md = p:getModData()
    keepPinsMd = md.ZeD_Pins and {} or nil   -- (the title bar pins: a pin past the third replaces the oldest)
    if keepPinsMd then for k, v in ipairs(md.ZeD_Pins) do keepPinsMd[k] = v end end
    CW():setPinned(true)
    CWm.openTab(0, "loot")
    p:getInventory():AddItem("Base.WaterBottle")
end)
-- Is the row really under its point (the list's own hit zone there is that thing)? One wheel notch toward it each
-- call. (The 4K run right-clicked a garment: its menu had Wear and Save to outfit, no Drink or Pin. The bottle's row was
-- past the long list's view, and its point landed on another row.)
local function revealRow(win, it)
    local c = win and win._mainContent
    local y = it and c and c._itemRenderYMap and c._itemRenderYMap[it]
    if not y or not c.hitZoneAt then return false end
    local ly = y + ZeD.T.rowH / 2
    if ly >= 0 and ly < c:getHeight() then
        local z = c:hitZoneAt(((c._itemRenderXMap and c._itemRenderXMap[it]) or 0) + 170, ly)
        if z and z.id == it then return true end
    end
    if c._scroll and c._scroll.handleMouseWheel then c._scroll:handleMouseWheel((y < 0) and -1 or 1) end
    return false
end
addWhen(5000, function() return revealRow(CW(), (rowOf(CW(), "Base.WaterBottle"))) end, function() end)
add(300, function()
    local it, x, y = rowOf(CW(), "Base.WaterBottle")
    -- (what the pin menu reads of it: a kind means "Pin to title bar" must be in its menu)
    say("the bottle's pin kind: " .. tostring(it and ZeD.Pins and ZeD.Pins.kindOf and ZeD.Pins.kindOf(it)))
    if check(it ~= nil and revealRow(CW(), it), "the bottle's row is on screen, under its point") then req("right " .. x .. " " .. y) end
end)
addWhen(4000, function() return hasOption(ZeD.tr("UI_ZeD_Pin_Pin")) end, function()   -- (the menu fills on the right-click; up to 4 s)
    readMenu("unpinned", ZeD.tr("UI_ZeD_Pin_Pin"))
    shot("1_pin")
    -- pin it by the option itself, as a click on it does
    local v = getPlayerContextMenu(0)
    for _, o in ipairs(v and v.options or {}) do
        if tostring(o.name) == ZeD.tr("UI_ZeD_Pin_Pin") and o.onSelect then pcall(o.onSelect, o.target, o.param1, o.param2) end
    end
    if v then pcall(function() v:hideAndChildren() end) end   -- (as zedqa_b8_seven_menus closes it)
end)
addWhen(5000, function() return revealRow(CW(), (rowOf(CW(), "Base.WaterBottle"))) end, function() end)
add(300, function()
    local it, x, y = rowOf(CW(), "Base.WaterBottle")
    if it then req("right " .. x .. " " .. y) end
end)
addWhen(4000, function() return hasOption(ZeD.tr("UI_ZeD_Pin_Unpin")) end, function()
    readMenu("pinned", ZeD.tr("UI_ZeD_Pin_Unpin"))
    shot("2_unpin")
    local v = getPlayerContextMenu(0)
    for _, o in ipairs(v and v.options or {}) do
        if tostring(o.name) == ZeD.tr("UI_ZeD_Pin_Unpin") and o.onSelect then pcall(o.onSelect, o.target, o.param1, o.param2) end
    end
    if v then pcall(function() v:hideAndChildren() end) end   -- (as zedqa_b8_seven_menus closes it)
end)
add(800, function()
    if keepPinsMd then p:getModData().ZeD_Pins = keepPinsMd end
    if keepTab and keepTab ~= "loot" then CWm.openTab(0, keepTab) end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function drive()
    local now = getTimestampMs()
    if pending then
        if done() then
            pending = nil; t0 = now
        elseif now - pendAt > 8000 then
            fail = fail + 1; say("ERR the mouse helper never answered: " .. tostring(pending)); pending = nil; t0 = now
        else
            return
        end
    end
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if st.cond then
        local okC, met = pcall(st.cond)
        if not (okC and met) and now - t0 < st.ms then return end
    elseif now - t0 < st.ms then
        return
    end
    t0 = now; i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
