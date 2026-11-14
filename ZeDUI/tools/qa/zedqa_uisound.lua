-- ZeDUI/tools/qa/zedqa_uisound.lua  (Nov 14 2026, QA, punch list 211): the "UI sounds" setting (Full / Quiet / Off).
-- getSoundManager is proxied to count playUISound; ZeD.uiSound is called under each setting, and a D-pad move in the
-- Character window under Off. grep "ZEDQA uis".
local function say(s) print("ZEDQA uis " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
local realGet = getSoundManager
local real = realGet()
local count = 0
local proxy = setmetatable({}, { __index = function(_, k)
    return function(_, ...)
        if k == "playUISound" then count = count + 1 end
        return real[k](real, ...)
    end
end })
getSoundManager = function() return proxy end
local opt
pcall(function() for k, v in pairs(ZeD.Settings) do if tostring(k):lower():find("uisound") and type(v) == "table" and v.getValue then opt = v; say("setting " .. tostring(k)) end end end)
check(opt ~= nil, "211 ZeD setup has a UI sounds choice")
check(type(ZeD.uiSound) == "function", "211 ZeD.uiSound exists")
local was = opt and opt:getValue()
local function try(v, label, want)
    if opt then opt:setValue(v) end
    count = 0
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    say(label .. ": ZeD.uiSound asked the game for " .. count .. " sound(s)")
    return count
end
local full = try(1, "Full", 1)
local quiet = try(2, "Quiet", 1)
local off = try(3, "Off", 0)
check(full == 1, "211 Full plays the click")
check(quiet == 1, "211 Quiet still plays it (quieter)")
check(off == 0, "211 Off plays nothing")
-- Off: a D-pad move in the Character window is silent too
local p = getPlayer()
local jd = JoypadState.players[1] or JoypadState.joypads[1]
pcall(function()
    ZeD_CharacterWindow.openTab(0, "equip")
end)
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(1500, function()
    local cw = ZeD_CharacterWindow.getInstance(0)
    ZeD.Input.Focus.claimFocus(cw)
    ZeD.Input.Focus.focusWhere(cw, "charMainInv", function() return true end)
    count = 0
    for _ = 1, 3 do ZeD.Input.Focus.dispatchJoypadDir(cw, "down", jd) end
end)
at(2200, function()
    check(count == 0, "211 Off: three D-pad moves in the Character window are silent (" .. count .. " sounds)")
    if opt and was then opt:setValue(was) end
    getSoundManager = realGet
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
