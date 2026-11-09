-- ZeDUI/tools/qa/zedqa_b9a_6.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 6): the drawer half rolls in instead of the
-- window switching to Loot. The director's sequence with the mouse: the Character window on Equip, both halves unpinned;
-- the pointer looks around the inventory for 3 s: the Equip drawer rolls in, the tab strip still shows Equip selected,
-- the title still names it; resting on the drawer's part of the bar brings it back on Equip as it was. Pressing Loot
-- while it is rolled in is Loot (the bar no longer brings Equip back). The World window the same on Maps (mirrored).
-- The REAL mouse (release_check_mouse.ps1), so run it with batch_b9a.ps1. grep "ZEDQA b9a6".
-- Screen size is read, never set. Pictures zqa_b9a6_<w>x<h>_<n>.png.
local TAG = "b9a6"
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
local function stripOf(w) return w[w == CW() and "_tabStripPanel" or "_actionTabStrip"] end
-- the drawer's part of the bar: above the tab strip
local function drawerBar(w) local s = stripOf(w); return math.floor(s:getAbsoluteX() + s:getWidth() / 2), math.floor(w:getAbsoluteY() + w:titleBarHeight() / 2) end
local function tabZone(w, id)
    local s = stripOf(w)
    for _, z in ipairs(s and s._hitZones or {}) do
        if z.id == "tab:" .. id then return math.floor(s:getAbsoluteX() + z.x + z.w / 2), math.floor(s:getAbsoluteY() + z.y + z.h / 2) end
    end
end

add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTabs.c, keepTabs.w = CW()._activeTab, WW()._activeTab
end)

local function turn(which)
    local function W() return which == "char" and CW() or WW() end
    local tab = which == "char" and "equip" or "maps"
    local title0
    add(1200, function()
        local w = W()
        H.setPin(w, "inv", false); H.setPin(w, "drawer", false)
        w:setWindowShaded(false)
        if which == "char" then CWm.openTab(0, tab) else WWm.openTab(0, tab) end
    end)
    add(800, function()
        local w = W()
        title0 = tostring(w.title)
        req("move " .. table.concat({ mid(w._mainContent) }, " "))   -- (looking around the inventory)
    end)
    add(3500, function()
        local w = W()
        check(H.foldedTab(w) == tab and not w._drawerOpen, which .. ": 3.5 s in the inventory: the drawer half rolled in")
        check(w._activeTab == tab, which .. ": ... the tab strip still on " .. tab .. " (no switch to Loot)")
        check(tostring(w.title) == title0, which .. ": ... the title unchanged (" .. tostring(w.title) .. ")")
        shot(which .. "_1_rolled_in")
        req("move " .. table.concat({ drawerBar(w) }, " "))
    end)
    add(1200, function()
        local w = W()
        check(w._drawerOpen and w._activeTab == tab and H.foldedTab(w) == nil, which .. ": resting on the drawer's part of the bar: back on " .. tab)
        shot(which .. "_2_back")
        req("move " .. table.concat({ mid(w._mainContent) }, " "))
    end)
    add(3500, function()
        local w = W()
        check(H.foldedTab(w) == tab, which .. ": (staged) rolled in again")
        local x, y = tabZone(w, "loot")
        if check(x ~= nil, which .. ": the Loot tab is on the strip") then req("left " .. x .. " " .. y) end
    end)
    add(1200, function()
        local w = W()
        check(w._activeTab == "loot" and H.foldedTab(w) == nil, which .. ": Loot pressed while rolled in: Loot, the fold forgotten")
        req("move " .. table.concat({ drawerBar(w) }, " "))
    end)
    add(1500, function()
        local w = W()
        check(w._activeTab == "loot" and not w._drawerOpen, which .. ": ... the bar no longer brings " .. tab .. " back")
        shot(which .. "_3_loot")
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
    CW():setWindowShaded(false); WW():setWindowShaded(false)
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
