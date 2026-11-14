-- ZeDUI/tools/qa/zedqa_padfix_c.lua  (Nov 14 2026, QA): Build's pad fixes 190, 191, 192 on the Character window, each tab
-- opened with ZeD_CharacterWindow.openTab(0, id), focus claimed, D-pad through ZeD's own dispatch (Focus.dispatchJoypadDir /
-- dispatchJoypadDown, the window's real path). Stops are listed for the record. grep "ZEDQA pfc".
local function say(s) print("ZEDQA pfc " .. tostring(s)) end
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
local cw
local function el() local e = cw and Focus.getFocusedElement(cw); return e and tostring(e.id) or "nil" end
local function zn() local z = cw and Focus.getFocusedZone(cw); return z and tostring(z.zone) or "nil" end
local function stops(zone)
    local t = {}
    for _, s in ipairs(Focus.flatElements(cw)) do if not zone or s.zone == zone then t[#t + 1] = tostring(s.id) end end
    return t
end
local function zonesSeen()
    local seen, t = {}, {}
    for _, s in ipairs(Focus.flatElements(cw)) do if not seen[s.zone] then seen[s.zone] = true; t[#t + 1] = tostring(s.zone) end end
    return table.concat(t, ", ")
end
local function dir(d) Focus.dispatchJoypadDir(cw, d, jd) end
local function btn(b) Focus.dispatchJoypadDown(cw, b, jd) end
local function open(id) ZeD_CharacterWindow.openTab(0, id); cw = ZeD_CharacterWindow.getInstance(0) end
local function claim() Focus.claimFocus(cw) end
local function scrollY()
    local v = "?"
    pcall(function()
        local c = cw.tabContent or cw._tabContent or cw.content
        v = tostring(c and (c.scrollY or c:getYScroll()) or cw._scrollY)
    end)
    return v
end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
-- 190 the ID card
at(300, function() open("identity") end)
at(1500, function()
    claim()
    say("190 zones: " .. zonesSeen())
    local ids = stops("charTabContent")
    say("190 tab stops (" .. #ids .. "): " .. table.concat(ids, " | ", 1, math.min(#ids, 50)))
    local photo, hair = false, nil
    for _, id in ipairs(ids) do
        local l = id:lower()
        if l:find("photo") or l:find("camera") or l:find("avatar") or l:find("portrait") or l:find("picture") then photo = true end
        if not hair and (l:find("hair") or l:find("beard")) then hair = id end
    end
    check(photo, "190a the ID card's picture or photo button is a pad stop")
    if hair then
        Focus.focusWhere(cw, "charTabContent", function(e) return tostring(e.id) == hair end)
        say("190 on " .. el() .. ", scroll " .. scrollY())
        ZEDQA_PFC_HAIR = { id = el(), scroll = scrollY() }
        dir("right")
    else say("190 no Hair/Beard stop found") end
end)
at(2300, function()
    if ZEDQA_PFC_HAIR then
        say("190 after Right: " .. el() .. ", scroll " .. scrollY())
        dir("left")
    end
end)
at(3100, function()
    if ZEDQA_PFC_HAIR then
        local s = scrollY()
        say("190 after Left: " .. el() .. ", scroll " .. s)
        check(s == ZEDQA_PFC_HAIR.scroll and zn() == "charTabContent", "190b Left/Right on Hair | Beard keeps the page in place (scroll " .. ZEDQA_PFC_HAIR.scroll .. " -> " .. s .. ", zone " .. zn() .. ")")
    end
end)
-- 191 the Journal's sub-tabs, a fast pass on the first open
at(3600, function() open("journal") end)
at(3700, function()
    claim()
    local sub = {}
    for _, s in ipairs(Focus.flatElements(cw)) do
        local l = tostring(s.id):lower()
        if l:find("journal") or l:find("notebook") or l:find("paper") or l:find("recipe") or l:find("loadout") then sub[#sub + 1] = s.zone .. ":" .. tostring(s.id) end
    end
    say("191 sub-tab stops: " .. table.concat(sub, " | "))
    local first = sub[1]
    if first then
        local z, id = first:match("^(.-):(.*)$")
        Focus.focusWhere(cw, z, function(e) return tostring(e.id) == id end)
        ZEDQA_PFC_SUB = z
        say("191 on " .. el() .. " in " .. zn())
        for _ = 1, 4 do dir("right") end
        say("191 right after 4 fast Rights: " .. el() .. " in " .. zn())
    else say("191 no sub-tab stops found") end
end)
at(5200, function()
    if ZEDQA_PFC_SUB then
        local inJ = zn() == ZEDQA_PFC_SUB
        say("191 settled: " .. el() .. " in " .. zn())
        check(inJ and el():lower():find("loadout") ~= nil, "191 four fast Rights on the first pass end on the last sub-tab, not in the inventory (" .. el() .. " / " .. zn() .. ")")
    end
end)
-- 192 Training
at(5700, function() open("skills") end)
at(7000, function()
    claim()
    local groups = {}
    for _, s in ipairs(Focus.flatElements(cw)) do local id = tostring(s.id); if id:find("^training:") and not id:find("#") then groups[#groups + 1] = s.zone .. ":" .. id end end
    say("192 training groups: " .. table.concat(groups, " | ", 1, math.min(#groups, 12)))
    local pick
    for _, g in ipairs(groups) do if g:lower():find("blacksmith") then pick = g end end
    pick = pick or groups[1]
    if not pick then say("192 no training group stop"); return end
    local z, id = pick:match("^(.-):(.*)$")
    ZEDQA_PFC_TR = id
    Focus.focusWhere(cw, z, function(e) return tostring(e.id) == id end)
    say("192 on " .. el())
    btn(Joypad.AButton)
end)
at(8000, function()
    if ZEDQA_PFC_TR then
        local books = {}
        for _, s in ipairs(Focus.flatElements(cw)) do local id = tostring(s.id); if id:sub(1, #ZEDQA_PFC_TR + 1) == ZEDQA_PFC_TR .. "#" then books[#books + 1] = id end end
        say("192 after A: on " .. el() .. "; its books: " .. table.concat(books, ", "))
        dir("down")
    end
end)
at(8800, function()
    if ZEDQA_PFC_TR then
        check(el() == ZEDQA_PFC_TR .. "#1", "192 Down from an open Training group lands on its first book (" .. el() .. ")")
    end
    pcall(function() getCore():TakeFullScreenshot("zqa_pfc_training.png") end)
    say("passed " .. nPass .. ", failed " .. nFail)
    say("DONE")
end)
local function tick()
    local now = getTimestampMs()
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
