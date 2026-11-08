-- ZeDUI/tools/qa/zedqa_b8a_sandbox.lua  (Nov 8 2026, hotfix beta 8a): single player, the in-game Sandbox options
-- answer the mouse. Beta 8's fault: the hidden in-game Options window ran the shared pointer first and took every
-- press, so no control in the Sandbox window worked. This script presses the window's own hit boxes through the real
-- pointer path (MM.pointer in update, the hidden Options window updating alongside): the pointer is moved onto each
-- box with Mouse.setXY and the button is scripted through ZeD.MouseTick.down (put back at the end). Pressed: a page,
-- a tick (a value), Undo changes, Apply and its question, Close. Then Escape twice: the pause window, not a stuck one.
-- Everything it changes is put back: the setting, the switch, History's entry.
-- grep "ZEDQA b8asb". Pictures: zqa_b8a_sb_*.png.
local TAG = "b8asb"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local npass, nfail = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8a_sb_" .. n .. ".png") end) end

local MM = ZeD.MainMenu
local opt = ZeD.Settings and ZeD.Settings.sandboxInGameOption
if not (opt and MM and ZeD_MMSandboxIG) or isClient() then say("ERR single player with ZeD's sandbox window only"); say("DONE"); return end
local switchWas = opt:getValue()
local MT = ZeD.MouseTick
local realDown = MT.down
local fakeDown = false
local so = getSandboxOptions()
local hist = ZeD.SandboxIG.history()
local histWas = #hist
local sw, rowName, rowWas

local function menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
local function toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
local function hitById(id)
    for _, h in ipairs(sw and sw._hits or {}) do if h.id == id then return h end end
    return nil
end
-- the first live tick in the rows on show, and its row's setting name
local function firstTick()
    local rows = sw:rowsFor(sw:pages()[sw.pageIdx])
    for _, h in ipairs(sw._hits or {}) do
        local i = tonumber(string.match(h.id, ":r(%d+):t1$") or "")
        local r = i and rows[i]
        local risk = ZeD.SandboxNotes and ZeD.SandboxNotes.risk and ZeD.SandboxNotes.risk(r and r.name or "")
        if r and r.name and not h.disabled and not sw:rowDisabled(r) and risk ~= "undo" then return h, r.name end
    end
    return nil
end

-- the plan: each entry waits ms, then runs
local plan, pi, pt = {}, 1, getTimestampMs()
local ins = nil
local function add(ms, fn) local e = { ms = ms, fn = fn }; if ins then table.insert(plan, ins, e); ins = ins + 1 else plan[#plan + 1] = e end end
-- a click on a hit box: point at it, press, release (each held across a few 100 ms UI updates)
local function click(getHit, what)
    local h
    add(200, function()
        h = getHit()
        if not check(h ~= nil, what .. ": the box is on show") then return end
        Mouse.setXY(math.floor(h.x + h.w / 2), math.floor(h.y + h.h / 2))
        fakeDown = false
    end)
    add(350, function() if h then fakeDown = true end end)
    add(350, function() fakeDown = false end)
    add(350, function() end)
end

local function drive()
    local st = plan[pi]
    if not st then return end
    local now = getTimestampMs()
    if now - pt < st.ms then return end
    pt = now
    pi = pi + 1
    ins = pi
    local ok, e = pcall(st.fn)
    ins = nil
    if not ok then nfail = nfail + 1; say("FAIL ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
    if pi > #plan then
        MT.down = realDown
        say(npass .. " passed, " .. nfail .. " failed")
        say("DONE")
        Events.OnPreUIDraw.Remove(drive)
    end
end

-- open the window over the paused game
add(100, function()
    opt:setValue(2)
    if not menuUp() then toggleMenu() end
end)
add(800, function()
    check(menuUp(), "the pause screen is up")
    MM.openSandboxIG()
end)
add(800, function()
    sw = MM.pauseSandbox
    check(sw and sw:isVisible() and MM.pauseView == "sandbox", "the Sandbox window is open")
    check(MM.pauseOpts and not MM.pauseOpts:isVisible(), "the in-game Options window is there, hidden (the case that broke)")
    MT.down = function() return fakeDown end
    shot("open")
end)

-- a page
local pageWas
add(100, function() pageWas = sw.pageIdx end)
click(function() return hitById(sw.kind .. ":page:" .. ((sw.pageIdx == 2) and 3 or 2)) end, "a page")
add(100, function()
    check(sw.pageIdx ~= pageWas, "a click on a page opens it", tostring(pageWas) .. " > " .. tostring(sw.pageIdx))
end)
-- a value, then Undo changes
local tickHit
add(100, function()
    tickHit, rowName = firstTick()
    if check(rowName ~= nil, "a tick on this page") then rowWas = so:getOptionByName(rowName):getValueAsString() end
end)
click(function() return tickHit end, "a tick")
add(100, function()
    check((sw.nDiff or 0) == 1 and sw.diff[rowName] ~= nil, "a click on a tick marks one change", sw.nDiff)
    shot("changed")
end)
click(function() return hitById(sw.kind .. ":undo") end, "Undo changes")
add(100, function() check((sw.nDiff or 0) == 0, "Undo changes takes it back", sw.nDiff) end)
-- the value again, then Apply and its question
add(100, function() tickHit = firstTick() end)
click(function() return tickHit end, "the tick again")
add(100, function() check((sw.nDiff or 0) == 1, "changed again", sw.nDiff) end)
click(function() return hitById(sw.kind .. ":apply") end, "Apply")
add(100, function()
    check(sw.confirm == "apply", "Apply asks first", tostring(sw.confirm))
    shot("ask")
end)
click(function() return hitById(sw.kind .. ":confirm:yes") end, "Apply's answer")
add(100, function()
    local now = so:getOptionByName(rowName):getValueAsString()
    check(now ~= rowWas, "the answer applies the setting", tostring(rowWas) .. " > " .. tostring(now))
    check(#hist == histWas + 1, "History has the apply")
    -- put the setting back (through the window's own calls: the clicks are proven)
    sw:putBack(rowName, rowWas)
    sw:applyNow()
    check(so:getOptionByName(rowName):getValueAsString() == rowWas, "the setting is back as it was")
    for _ = 1, #hist - histWas do table.remove(hist) end
end)
-- Close
add(300, function() sw:showPage(sw:pages()[1].raw) end)
click(function() return hitById(sw.kind .. ":back") end, "Close")
add(100, function()
    check(MM.pauseView == "pause" and not sw:isVisible(), "Close goes back to the pause window", MM.pauseView)
    shot("closed")
end)
-- Escape out and back: the pause window, not a stuck Sandbox window
add(200, function() MT.down = realDown; if menuUp() then toggleMenu() end end)
add(800, function()
    check(not menuUp(), "Escape leaves the pause screen")
    toggleMenu()
end)
add(800, function()
    check(menuUp() and MM.pause and MM.pause:isVisible() and MM.pauseView == "pause", "Escape again opens the pause window", MM.pauseView)
    opt:setValue(switchWas or 1)
    toggleMenu()
end)
add(500, function() say("MANUAL a quick real click on a page, a value, Undo, Apply and Close; the controller still drives it") end)
Events.OnPreUIDraw.Add(drive)   -- (drawn frames run while the game is paused; OnTick may not)
say("start")
