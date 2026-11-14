-- ZeDUI/tools/qa/zedqa_sound_count.lua  (Nov 14 2026, QA, punch list 210): counts the UI sounds asked for per pad press and
-- per frame. getSoundManager is swapped for a proxy that forwards every call to the real one and tallies playUISound by
-- name and frame. Then D-pad walks: the inventory list, the tab strip, the container strip, and a held direction.
-- grep "ZEDQA snd".
local function say(s) print("ZEDQA snd " .. tostring(s)) end
local realGet = getSoundManager
local real = realGet()
local frame, perFrame, maxFrame, maxFrameAt = 0, 0, 0, ""
local window = {}
local total = {}
local proxy = setmetatable({}, { __index = function(_, k)
    return function(_, ...)
        if k == "playUISound" then
            local n = tostring((...))
            perFrame = perFrame + 1
            window[n] = (window[n] or 0) + 1
            total[n] = (total[n] or 0) + 1
        end
        return real[k](real, ...)
    end
end })
getSoundManager = function() return proxy end
local function flush(tag)
    local t = {}
    for k, v in pairs(window) do t[#t + 1] = k .. " x" .. v end
    say(tag .. ": " .. (#t > 0 and table.concat(t, ", ") or "no sound"))
    window = {}
end
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
local Focus = ZeD.Input.Focus
local cw
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
local function dir(d) Focus.dispatchJoypadDir(cw, d, jd) end
at(300, function() ZeD_CharacterWindow.openTab(0, "equip"); cw = ZeD_CharacterWindow.getInstance(0) end)
at(1500, function() Focus.claimFocus(cw); flush("opening the windows") end)
-- one press at a time down the inventory list
for k = 1, 8 do
    at(1500 + k * 400, function() if k == 1 then Focus.focusWhere(cw, "charMainInv", function() return true end) end; dir("down") end)
    at(1500 + k * 400 + 350, function() flush("list Down #" .. k) end)
end
-- the tab strip
at(5200, function() Focus.focusWhere(cw, "charTabBar", function() return true end); flush("to the tab strip") end)
for k = 1, 5 do
    at(5200 + k * 400, function() dir("down") end)
    at(5200 + k * 400 + 350, function() flush("tab Down #" .. k) end)
end
-- fast: 10 presses in one frame burst each 50 ms
at(7800, function() Focus.focusWhere(cw, "charMainInv", function() return true end); flush("back to the list") end)
for k = 1, 10 do at(7800 + k * 50, function() dir("down") end) end
at(8500, function() flush("10 fast list Downs") end)
-- the real pad path: the game calls BOTH focus:onJoypadDown(DPadDown) and focus:onJoypadDirDown in the same frame
at(8700, function() Focus.focusWhere(cw, "charMainInv", function() return true end); flush("before the dual presses") end)
for k = 1, 5 do
    at(8700 + k * 400, function() pcall(function() cw:onJoypadDown(Joypad.DPadDown, jd) end); pcall(function() cw:onJoypadDirDown(jd) end) end)
    at(8700 + k * 400 + 350, function() flush("dual press #" .. k .. " (onJoypadDown + onJoypadDirDown, one frame)") end)
end
for k = 1, 5 do
    at(11000 + k * 400, function() pcall(function() cw:onJoypadDirDown(jd) end) end)
    at(11000 + k * 400 + 350, function() flush("dir only #" .. k) end)
end
at(13500, function()
    getSoundManager = realGet
    local t = {}
    for k, v in pairs(total) do t[#t + 1] = k .. " x" .. v end
    say("total: " .. table.concat(t, ", "))
    say("most sounds in one frame: " .. maxFrame .. " (" .. maxFrameAt .. ")")
    say("DONE")
end)
local cur = "start"
local function tick()
    local now = getTimestampMs()
    if not t0 then t0 = now end
    frame = frame + 1
    if perFrame > maxFrame then maxFrame = perFrame; maxFrameAt = cur .. " frame " .. frame end
    perFrame = 0
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        cur = "step " .. i
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
