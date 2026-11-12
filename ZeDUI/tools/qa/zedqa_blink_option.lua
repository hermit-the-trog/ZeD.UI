-- ZeDUI/tools/qa/zedqa_blink_option.lua  (Nov 11 2026, QA): the setup option "Blink the low-health pixel": it exists, is On by default, On blinks (lit and dark both seen from ZeD_Window.pixelLit(true) over
-- two seconds), Off holds the pixel solid. The option is put back as it was. grep "ZEDQA blk".
local function say(s) print("ZEDQA blk " .. tostring(s)) end
local S = ZeD.Settings
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local o = S and S.healthBlinkOption
check(o ~= nil, "the option exists in ZeD's setup")
local was = o and o:getValue()
local function sample(ms, cb)
    local t0, lit, dark = getTimestampMs(), 0, 0
    local function f()
        if ZeD_Window.pixelLit(true) then lit = lit + 1 else dark = dark + 1 end
        if getTimestampMs() - t0 > ms then Events.OnTick.Remove(f); cb(lit, dark) end
    end
    Events.OnTick.Add(f)
end
local label = ZeD.tr("UI_ZeD_Settings_HealthBlink")
say("label '" .. tostring(label) .. "'; value now " .. tostring(was) .. "; S.healthBlink() " .. tostring(S and S.healthBlink and S.healthBlink()))
check(label == "Blink the low-health pixel", "its label")
check(S.healthBlink() == true, "On by default (as read now)", tostring(S.healthBlink()))
pcall(function() o:setValue(2) end)
sample(2500, function(l1, d1)
    check(l1 > 0 and d1 > 0, "On: the pixel blinks (lit and dark frames both seen)", l1 .. " lit, " .. d1 .. " dark")
    pcall(function() o:setValue(1) end)
    check(S.healthBlink() == false, "Off reads off")
    sample(2500, function(l2, d2)
        check(l2 > 0 and d2 == 0, "Off: the pixel stays solid", l2 .. " lit, " .. d2 .. " dark")
        pcall(function() o:setValue(was) end)
        say("fails " .. fails)
        say("DONE")
    end)
end)
say("start")
