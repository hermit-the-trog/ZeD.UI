-- ZeDUI/tools/qa/zedqa_cfg_large.lua  (Nov 20 2026, QA; tag cfl): Large text for the rest of the run, set on ZeD's own options (the
-- values only, then ZeD.Settings.reapplyFromOptions and a layout reset), so the options window agrees with what is on
-- screen. The runner puts ModOptions.ini back after the run. For the deep runs (release_test_<name>.txt). grep "ZEDQA cfl".
local zo = nil
pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end)
local set = {}
for pair in string.gmatch("textSize=2", "[^ ]+") do
    local id, v = pair:match("^(.-)=(.+)$")
    local o = zo and zo.dict and zo.dict[id]
    local ok = o ~= nil and pcall(function() o:setValue(tonumber(v)) end)
    set[#set + 1] = id .. "=" .. v .. (ok and "" or " FAILED")
end
pcall(ZeD.Settings.reapplyFromOptions)
local n = 0
local function f()
    n = n + 1
    if n == 20 then pcall(ZeD_Window.resetLayout) end
    if n < 40 then return end
    Events.OnTick.Remove(f)
    print("ZEDQA cfl " .. ((table.concat(set, ", "):find("FAILED", 1, true)) and "FAIL" or "PASS") .. " set " .. table.concat(set, ", ") .. " | now " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentSize) .. " lite " .. tostring(ZeD.Settings.lite()))
    print("ZEDQA cfl DONE")
end
Events.OnTick.Add(f)
