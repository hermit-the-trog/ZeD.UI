-- ZeDUI/tools/qa/zedqa_padfix_train.lua  (Nov 14 2026, QA): 192 on a6f4ab1fd. Character window on the Skills tab with the
-- pad: A on a Training group (Blacksmithing if there) opens it, then Down must land on that group's first book
-- ("training:<group>#1"), not the next group. grep "ZEDQA pft".
local function say(s) print("ZEDQA pft " .. tostring(s)) end
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
local function elId(w) local e = w and Focus.getFocusedElement(w); return e and tostring(e.id) or "nil" end
local function zoneOf(w) local z = w and Focus.getFocusedZone(w); return z and tostring(z.zone) or "nil" end
local function flat(w, pat)
    local t = {}
    for _, s in ipairs(Focus.flatElements(w)) do if tostring(s.id):find(pat) then t[#t + 1] = tostring(s.id) end end
    return t
end
local group
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function()
    cw = ZeD_CharacterWindow.getInstance(0)
    pcall(function() if not cw:isReallyVisible() then ZeD.toggleBothPaired(0) end end)
    Focus.claimFocus(cw)
    local tabs = flat(cw, ".")
    local ids = {}
    for _, s in ipairs(Focus.flatElements(cw)) do if s.zone == "charTabBar" then ids[#ids + 1] = tostring(s.id) end end
    say("tab bar: " .. table.concat(ids, ", "))
    Focus.focusWhere(cw, "charTabBar", function(e) return tostring(e.id):lower():find("skill") ~= nil end)
    say("on tab " .. elId(cw))
    Focus.dispatchJoypadDown(cw, Joypad.AButton, jd)
end)
at(2000, function()
    local all = {}; for _, s in ipairs(Focus.flatElements(cw)) do all[#all + 1] = tostring(s.zone) .. ":" .. tostring(s.id) end; say("stops: " .. table.concat(all, " | ", 1, math.min(#all, 60)))
    local groups = flat(cw, "^training:[^#]+$")
    say("training groups: " .. table.concat(groups, ", "))
    for _, g in ipairs(groups) do if g:lower():find("blacksmith") then group = g end end
    group = group or groups[1]
    if not group then say("ERR no training group stop"); return end
    local zname
    for _, s in ipairs(Focus.flatElements(cw)) do if tostring(s.id) == group then zname = s.zone end end
    Focus.focusWhere(cw, zname, function(e) return tostring(e.id) == group end)
    say("on " .. elId(cw) .. " in " .. zoneOf(cw))
    Focus.dispatchJoypadDown(cw, Joypad.AButton, jd)
end)
at(3500, function()
    say("after A: on " .. elId(cw) .. "; its books: " .. table.concat(flat(cw, "^" .. (group or "x"):gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%0") .. "#"), ", "))
    Focus.dispatchJoypadDir(cw, "down", jd)
end)
at(4500, function()
    local now = elId(cw)
    say("after Down: on " .. now)
    check(group and now == group .. "#1", "192 Down from an open Training group lands on its first book (" .. now .. ", want " .. tostring(group) .. "#1)")
    pcall(function() getCore():TakeFullScreenshot("zqa_pft_training.png") end)
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
