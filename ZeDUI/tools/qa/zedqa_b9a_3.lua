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
    -- Each half's part of the rolled bar, read from the rolled window itself (ZeD.Halves.split: where the halves meet on
    -- the bar), at the middle of that part. Read before the window rolled, a target went stale: a drawer that folded first
    -- narrows the window, and the old point was off it.
    local function partX(w, part)
        local split = H.split(w)
        local width = w:getWidth()
        local left = (part == "drawer") == (which == "char")   -- (the Character's drawer is its left part)
        return math.floor(w:getAbsoluteX() + (left and split / 2 or (split + width) / 2))
    end
    local function barY(w) return math.floor(w:getAbsoluteY() + w:titleBarHeight() / 2) end
    local wantX, wantY
    for _, part in ipairs({ "inventory", "drawer" }) do
        -- The staging: the window down and whole with both pins on (nothing rolls), the pointer away from both windows,
        -- and only then both pins off, so both halves leave together and roll at once: the whole bar, the drawer not
        -- folded first. (Unpinned first, a pointer resting in the list folded the drawer before the window rolled.)
        add(1200, function()
            local w = W()
            H.setPin(w, "inv", true); H.setPin(w, "drawer", true)
            w:setWindowShaded(false)
            if w._rolled and ZeD.Curtain then ZeD.Curtain.finishUnroll(w) end
            if H.showAll then H.showAll(w) end
            if which == "char" then CWm.openTab(0, tab) else WWm.openTab(0, tab) end
        end)
        add(800, function() req("move " .. math.floor(sw / 2) .. " " .. (sh - 60)) end)   -- (away from both windows)
        add(300, function()
            local w = W()
            check(not w.windowShaded and not w._rolled and w._drawerOpen and H.foldedTab(w) == nil, which .. " " .. part .. ": (staged) down and whole on " .. tab .. ", pinned")
            H.setPin(w, "inv", false); H.setPin(w, "drawer", false)
        end)
        -- (both halves roll 2 s after the pin comes off: wait on the window's state, up to 6 s)
        addWhen(6000, function() return W().windowShaded == true end, function()
            local w = W()
            check(w.windowShaded == true and w._activeTab == tab and H.foldedTab(w) == nil,
                which .. " " .. part .. ": (staged) both halves unpinned, the whole window rolled up on " .. tab .. ", the drawer not folded first")
            wantX, wantY = partX(w, part), barY(w)
            say(which .. " " .. part .. ": its part of the rolled bar at " .. wantX .. "," .. wantY .. " (the halves meet at " .. H.split(w) .. " of " .. w:getWidth() .. ")")
            req("move " .. wantX .. " " .. wantY)
        end)
        add(200, function()
            -- (where the game sees the pointer: a request the helper missed shows here, not as a halves fault)
            say(which .. " " .. part .. ": the pointer is at " .. getMouseX() .. "," .. getMouseY() .. " (asked " .. tostring(wantX) .. "," .. tostring(wantY) .. ")")
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
