-- ZeDUI/tools/qa/zedqa_b9a_9.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 9, the director's "Just pins"): the roll boxes
-- are gone from the Character and World title bars; the pins stay. With the mouse: each window on a tab with its
-- inventory beside the drawer, nothing pinned: no roll box after the title, the title keeps that room, a real click
-- where the box was rolls nothing; the unpinned halves still roll with the pointer and a pinned half stays down; a
-- click on the open tab still folds the drawer by hand. The controller's ring has no stop for a roll box, only the
-- two pins. The REAL mouse (release_check_mouse.ps1), so run it with batch_b9a.ps1. grep "ZEDQA b9a9".
-- Screen size is read, never set. Pictures zqa_b9a9_<w>x<h>_<n>.png.
local TAG = "b9a9"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, s) if ok then pass = pass + 1 else fail = fail + 1 end; say((ok and "PASS " or "FAIL ") .. s); return ok end
if ZEDQA_HOME then ZEDQA_HOME(TAG) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
say("screen " .. sw .. "x" .. sh)
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local H = ZeD.Halves
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local keepPins, keepTabs = nil, {}
local function mid(panel) return math.floor(panel:getAbsoluteX() + panel:getWidth() / 2), math.floor(panel:getAbsoluteY() + panel:getHeight() / 2) end
-- where the roll box sat: right after the title as drawn
local function boxSpot(w)
    local T = ZeD.T
    local titleX = T.sp.sm + T.closeBoxSz + T.sp.md + H.titleShift(w)
    local tw = w._titleShownW or ZeD.TM:MeasureStringX(T.fontF3, tostring(w.title or ""))
    return math.floor(w:getAbsoluteX() + titleX + tw + T.sp.titleBoxPad + T.px(2) + T.closeBoxSz / 2), math.floor(w:getAbsoluteY() + w:titleBarHeight() / 2)
end

add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTabs.c, keepTabs.w = CW()._activeTab, WW()._activeTab
end)

local function turn(which)
    local function W() return which == "char" and CW() or WW() end
    local tab = which == "char" and "health" or "maps"
    add(1500, function()
        local w = W()
        H.setPin(w, "inv", false); H.setPin(w, "drawer", true)   -- (the drawer pinned: the window stays down to look at)
        w:setWindowShaded(false)
        if which == "char" then CWm.openTab(0, tab) else WWm.openTab(0, tab) end
        req("move " .. table.concat({ mid(w._mainContent) }, " "))
    end)
    add(800, function()
        local w = W()
        check(w._curtain and w._curtain.canRoll(), which .. ": (staged) on " .. tab .. " with the inventory beside the drawer (a roll box would show)")
        check(w._rollBtn == nil, which .. ": no roll box after the title")
        check(w._titleReserve == nil, which .. ": the title keeps no room for one")
        local found = false
        for _, z in ipairs(w._focusRing or {}) do
            for _, e in ipairs(z.elements or {}) do if tostring(e.id):find("curtain:roll", 1, true) and e.id ~= "curtain:unroll" then found = true end end
        end
        check(not found, which .. ": the controller's ring has no roll box stop")
        shot(which .. "_1_bar")
        req("left " .. table.concat({ boxSpot(w) }, " "))
    end)
    add(1000, function()
        local w = W()
        check(not w._rolled and not w._halves.inv.hand, which .. ": a real click where the box was rolls nothing")
        req("move " .. table.concat({ mid(w[which == "char" and "_tabStripPanel" or "_actionTabStrip"]) }, " "))
    end)
    add(3200, function()
        local w = W()
        check(w._rolled == true and w._drawerOpen, which .. ": the pointer off the inventory 3 s: the unpinned inventory rolls, the pinned drawer stays")
        shot(which .. "_2_rolled")
        local rod = w._rod
        if rod then req("move " .. math.floor(rod:getAbsoluteX() + rod:getWidth() / 2) .. " " .. math.floor(rod:getAbsoluteY() + w:titleBarHeight() / 2)) end
    end)
    add(1000, function()
        local w = W()
        check(not w._rolled, which .. ": resting on its rod brings it down (no roll by hand to keep it up)")
        local s = w[which == "char" and "_tabStripPanel" or "_actionTabStrip"]
        for _, z in ipairs(s and s._hitZones or {}) do
            if z.id == "tab:" .. tab then req("left " .. math.floor(s:getAbsoluteX() + z.x + z.w / 2) .. " " .. math.floor(s:getAbsoluteY() + z.y + z.h / 2)) end
        end
    end)
    add(1000, function()
        local w = W()
        check(not w._drawerOpen and w._activeTab == "loot", which .. ": a click on the open tab still folds the drawer by hand")
        shot(which .. "_3_tab_folds")
    end)
end
turn("char")
turn("world")

add(1000, function()
    if keepPins then
        p:getModData().ZeD_WinPinned = keepPins
        for _, pair in ipairs({ { CW(), "char" }, { WW(), "world" } }) do
            local win, k = pair[1], pair[2]
            local a, b = keepPins[k .. "Inv"], keepPins[k .. "Tabs"]
            if a == nil and b == nil then a, b = keepPins[k] == true, keepPins[k] == true end
            H.setPin(win, "inv", a == true); H.setPin(win, "drawer", b == true)
        end
    end
    if keepTabs.c and keepTabs.c ~= "loot" then CWm.openTab(0, keepTabs.c) end
    if keepTabs.w and keepTabs.w ~= "loot" then WWm.openTab(0, keepTabs.w) end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
