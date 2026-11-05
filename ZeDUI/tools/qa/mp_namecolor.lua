-- ZeDUI/tools/qa/mp_namecolor.lua  (Nov 5 2026, QA; b905ac80): the chat's Name color on the multiplayer client. The
-- menu's nine colors, one picked the menu's way (its onFire), your name drawing in it, the welcome line, then your
-- color put back (it is the game's own option, saved in options.ini). Picture: mnc_chat.png. grep "ZEDQA mnc".
local function say(s) print("ZEDQA mnc " .. tostring(s)) end
local C = ZeD.Chat
local p = getPlayer()
local me = p:getUsername()
local was = C.myColor()
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function c2s(c) return c and string.format("%.2f,%.2f,%.2f", c.r, c.g, c.b) or "nil" end
add(300, function()
    say("my color before " .. c2s(was))
    local items = C.menuItems()
    local kids = items[1] and items[1].children or {}
    local names = {}
    for _, k in ipairs(kids) do names[#names + 1] = tostring(k.name) .. ((k.checked and k.checked()) and "*" or "") end
    say("Name color menu: " .. tostring(items[1] and items[1].name) .. " [" .. table.concat(names, ", ") .. "]")
    PICK = kids[3]
    if PICK then PICK.onFire(); say("picked " .. tostring(PICK.name)) end
    C.open(false)
end)
add(1500, function()
    local now = C.myColor()
    say("my color now " .. c2s(now) .. ", the game's speak color " .. (function() local s = p:getSpeakColour(); return s and string.format("%.2f,%.2f,%.2f", s:getR(), s:getG(), s:getB()) or "nil" end)())
    say("my name's ink " .. c2s(C.nameInk(me)))
    C.send("/all name color check")
end)
add(2500, function()
    local first = C.lines[1]
    say("first line: " .. tostring(first and first.text))
    pcall(function() getCore():TakeFullScreenshot("mnc_chat.png") end)
    -- put the color back
    if was then C.setMyColor(was); say("put back " .. c2s(C.myColor())) end
    if C.win then C.win:setVisible(false) end
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
