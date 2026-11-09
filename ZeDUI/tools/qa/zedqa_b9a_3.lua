-- ZeDUI/tools/qa/zedqa_b9a_3.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 3): each half's part of a rolled title bar
-- brings back only its own half. The director's sequence with the mouse: both halves unpinned, the whole window rolled
-- up; the pointer rests on the inventory's part of the bar (the Character window's right, the World window's left):
-- the window comes down with the inventory and the drawer still rolled in, on its tab (the title still names it; the
-- window must not come back as the whole window on Loot). Then the drawer's part: the drawer and the inventory under
-- its rod. Both windows. The REAL mouse (release_check_mouse.ps1), so run it with batch_b9a.ps1. grep "ZEDQA b9a3".
-- Screen size is read, never set. Pictures zqa_b9a3_<w>x<h>_<n>.png.
local TAG = "b9a3"
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

add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTabs.c, keepTabs.w = CW()._activeTab, WW()._activeTab
end)

local function turn(which)
    local function W() return which == "char" and CW() or WW() end
    local tab = which == "char" and "equip" or "maps"
    -- the inventory's part of the bar (window-local x): the Character's right quarter, the World's left quarter
    local function invX(w) return math.floor(w:getAbsoluteX() + ((which == "char") and w:getWidth() * 0.8 or w:getWidth() * 0.2)) end
    local function drwX(w) return math.floor(w:getAbsoluteX() + ((which == "char") and w:getWidth() * 0.2 or w:getWidth() * 0.8)) end
    local function barY(w) return math.floor(w:getAbsoluteY() + w:titleBarHeight() / 2) end
    for _, part in ipairs({ "inventory", "drawer" }) do
        add(1200, function()
            local w = W()
            H.setPin(w, "inv", false); H.setPin(w, "drawer", false)
            w:setWindowShaded(false)
            if which == "char" then CWm.openTab(0, tab) else WWm.openTab(0, tab) end
            req("move " .. math.floor(sw / 2) .. " " .. (sh - 60))   -- (away from both windows)
        end)
        add(3500, function()
            local w = W()
            check(w.windowShaded == true and w._activeTab == tab, which .. " " .. part .. ": (staged) both halves unpinned, the whole window rolled up on " .. tab)
            local x = (part == "inventory") and invX(w) or drwX(w)
            req("move " .. x .. " " .. barY(w))
        end)
        add(1200, function()
            local w = W()
            check(not w.windowShaded, which .. " " .. part .. ": resting on its part of the bar brings the window down")
            if part == "inventory" then
                check(not w._rolled and not w._drawerOpen and H.foldedTab(w) == tab, which .. ": ... with only the inventory: the drawer still rolled in")
                check(w._activeTab == tab, which .. ": ... and the window still on " .. tab .. " (not Loot)")
                check(tostring(w.title):find("  +  ", 1, true) ~= nil, which .. ": ... the title still names the tab (" .. tostring(w.title) .. ")")
            else
                check(w._drawerOpen and w._rolled == true, which .. ": ... with only the drawer: the inventory under its rod")
            end
            shot(which .. "_" .. part)
        end)
    end
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
