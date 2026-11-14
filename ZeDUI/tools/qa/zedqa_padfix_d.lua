-- ZeDUI/tools/qa/zedqa_padfix_d.lua  (Nov 14 2026, QA): 190b, 191, 192, 198 and 199 on 722282464, with Build's stop ids.
-- Pad through ZeD's own dispatch on the focused window. Pictures for 198. grep "ZEDQA pfd2".
local function say(s) print("ZEDQA pfd2 " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local jd = JoypadState.players[1]
if not jd then
    for i = 0, 15 do
        local c = JoypadState.controllers[i]
        if c and c.connected then
            pcall(function() triggerEvent("OnJoypadActivate", i) end)
            jd = JoypadState.players[1] or JoypadState.joypads[1]
            if jd and not JoypadState.players[1] then pcall(function() p:setJoypadBind(i); jd.player = 0; JoypadState.players[1] = jd end) end
            break
        end
    end
end
jd = JoypadState.players[1]
if not jd then say("ERR no pad"); say("DONE"); return end
local Focus = ZeD.Input.Focus
local inv = p:getInventory()
local w
local function el() local e = w and Focus.getFocusedElement(w); return e and tostring(e.id) or "nil" end
local function zn() local z = w and Focus.getFocusedZone(w); return z and tostring(z.zone) or "nil" end
local function find(pred) for _, s in ipairs(Focus.flatElements(w)) do if pred(tostring(s.id)) then return s end end end
local function go(pred) local s = find(pred); if s then Focus.focusWhere(w, s.zone, function(e) return tostring(e.id) == tostring(s.id) end) end; return s end
local function list(pat, max) local t = {}; for _, s in ipairs(Focus.flatElements(w)) do local id = tostring(s.id); if id:find(pat) then t[#t + 1] = id end end; return table.concat(t, " | ", 1, math.min(#t, max or 30)) end
local function dir(d) Focus.dispatchJoypadDir(w, d, jd) end
local releaseAt = nil
local function A() local e = Focus.getFocusedElement(w); if e and e.onActivate then local ok, er = pcall(e.onActivate, w, e); if not ok then say("onActivate ERR " .. tostring(er)) end else say("no onActivate on " .. tostring(e and e.id)) end end
local function B() Focus.dispatchJoypadDown(w, Joypad.BButton, jd) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot(n) end) end
-- staging: no scissors or razor (190b), two Blacksmithing books (192), a newspaper (199)
local removed = {}
for _, t in ipairs({ "Scissors", "Razor", "StraightRazor" }) do
    local it = inv:getFirstType(t)
    while it do inv:Remove(it); removed[#removed + 1] = t; it = inv:getFirstType(t) end
end
local added = {}
for _, t in ipairs({ "Base.BookBlacksmith1", "Base.BookBlacksmith2", "Base.Newspaper" }) do local it = inv:AddItem(t); if it then added[#added + 1] = it end end
say("staged: took out " .. #removed .. " cutting tools, added " .. #added .. " items")
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
-- 190b
at(300, function() ZeD_CharacterWindow.openTab(0, "identity"); w = ZeD_CharacterWindow.getInstance(0) end)
at(1500, function()
    Focus.claimFocus(w)
    local s = go(function(id) return id == "hb:part" end)
    say("190b on " .. el() .. ", offset " .. tostring(w._idOffPx))
    ZEDQA_PFD2_OFF = w._idOffPx
    if s then dir("right") end
end)
at(2300, function() say("190b after Right: " .. el() .. ", offset " .. tostring(w._idOffPx)); dir("left") end)
at(3100, function()
    say("190b after Left: " .. el() .. ", offset " .. tostring(w._idOffPx))
    check(w._idOffPx == ZEDQA_PFD2_OFF and el():find("^hb:") ~= nil, "190b Left/Right on Hair | Beard keeps the page in place (offset " .. tostring(ZEDQA_PFD2_OFF) .. " -> " .. tostring(w._idOffPx) .. ", on " .. el() .. ")")
end)
-- 191, first open of the Journal this launch
at(3500, function() ZeD_CharacterWindow.openTab(0, "journal"); w = ZeD_CharacterWindow.getInstance(0) end)
at(3600, function()
    Focus.claimFocus(w)
    say("191 sub-tabs: " .. list("^jtab:"))
    go(function(id) return id == "jtab:1" end)
    say("191 on " .. el())
    for _ = 1, 4 do dir("right") end
end)
at(5000, function()
    say("191 after 4 fast Rights: " .. el() .. " in " .. zn())
    check(el() == "jtab:5", "191 four fast Rights on the first pass end on the last sub-tab (" .. el() .. " / " .. zn() .. ")")
end)
-- 198 Recipes' Sort
at(5400, function() go(function(id) return id == "jtab:4" end); A() end)
at(6600, function()
    say("198 recipes stops with sort/show/cat: " .. list("[Ss]ort", 10) .. " || " .. list("[Ss]how", 10) .. " || " .. list("[Cc]at", 10))
    local s = go(function(id) return id:lower():find("sort") ~= nil end)
    say("198 on " .. el())
    if s then A() end
end)
at(7600, function() say("198 after A: " .. el()); shot("zqa_pfd2_recipes_sort.png") end)
at(8000, function() B() end)
-- 199 Papers: open the newspaper, Read with A, the queue after
at(8600, function() pcall(function() w._jrecipeState.sortMenuOpen = false; w._jrecipeState.showMenuOpen = false end); w._journalSubTab = 3; say("199 page set to 3") end)
at(9800, function()
    say("199 papers stops: " .. list("^jr:", 15) .. " || " .. list("[Pp]aper", 10))
    local s = go(function(id) local l = id:lower(); return l:find("^jr:paper:knox") end)
    say("199 on " .. el())
    if s then A() end
end)
at(10800, function()
    if ISInventoryPaneContextMenu and not ZEDQA_PFD2_LIT then
        ZEDQA_PFD2_LIT = true
        local o = ISInventoryPaneContextMenu.onLiteratureItems
        ISInventoryPaneContextMenu.onLiteratureItems = function(...) say("199 onLiteratureItems ran"); return o(...) end
    end
    local s = go(function(id) return id == "jr:read" end)
    say("199 on " .. el() .. " (jr:read found " .. tostring(s ~= nil) .. ")")
    if s then A() end
end)
at(11300, function()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local t = {}
    if q and q.queue then for _, a in ipairs(q.queue) do t[#t + 1] = tostring(a.Type) end end
    say("199 queue after A on Read: " .. (#t > 0 and table.concat(t, " > ") or "(empty)"))
    check(#t > 0, "199 A on a paper's Read queues the read")
    pcall(function() local q2 = ISTimedActionQueue.getTimedActionQueue(p); if q2 and q2.clearQueue then q2:clearQueue() end end)
end)
-- 192 Training with books
at(11800, function() ZeD_CharacterWindow.openTab(0, "skills"); w = ZeD_CharacterWindow.getInstance(0) end)
at(13000, function()
    Focus.claimFocus(w)
    local s = go(function(id) return id:find("^training:") and id:find("Blacksmith") and not id:find("#") end)
    say("192 on " .. el())
    if s then A() end
end)
at(14000, function()
    say("192 books now: " .. list("Blacksmith#", 5))
    dir("down")
end)
at(14800, function()
    check(el():find("Blacksmith#1") ~= nil, "192 Down from an open Training group lands on its first book (" .. el() .. ")")
    shot("zqa_pfd2_training.png")
end)
-- 198 Building's Show pull-up in the World window
at(15300, function()
    local ok, e = pcall(function() ZeD_WorldWindow.openTab(0, "building") end)
    if not ok then say("198 World openTab failed: " .. tostring(e)) end
    w = nil; for _, x in ipairs(ZeD.windowsFor(0) or {}) do if x._buildState then w = x end end
    if not w then pcall(function() for _, x in pairs(ZeD.windowsFor(0)) do if type(x) == "table" and x._buildState then w = x end end end) end
    say("198 world window " .. tostring(w and w._zedLabel) .. " buildState " .. tostring(w and w._buildState ~= nil))
    pcall(function() ZeD.CraftingCore.openPopMenu(w._buildState, "show") end)
end)
at(16600, function()
    if true then return end
    Focus.claimFocus(w)
    say("198 building stops with show/sort: " .. list("[Ss]how", 10) .. " || " .. list("[Ss]ort", 10))
    local s = go(function(id) return id:lower():find("show") ~= nil end)
    say("198 on " .. el())
    if s then A() end
end)
at(17600, function() say("198 after A: " .. el()); shot("zqa_pfd2_building_show.png") end)
at(18000, function()
    B()
    for _, it in ipairs(added) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    for _, t in ipairs(removed) do inv:AddItem("Base." .. t) end
    say("passed " .. nPass .. ", failed " .. nFail)
    say("DONE")
end)
local function tick()
    local now = getTimestampMs()
    if releaseAt and now >= releaseAt then Focus.qaButton("A", false, 0); releaseAt = nil; ZEDQA_PFD2_NILAT = now + 120 end
    if ZEDQA_PFD2_NILAT and now >= ZEDQA_PFD2_NILAT then Focus.qaButton("A", nil, 0); ZEDQA_PFD2_NILAT = nil end
    if not t0 then t0 = now end
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
