-- ZeDUI/tools/qa/zedqa_b8_probe2.lua (Nov 8 2026, QA): what the radio script manager and a TV channel offer on 42.21. grep "ZEDQA b8p2".
local function say(s) print("ZEDQA b8p2 " .. tostring(s)) end
local function try(label, f)
    local ok, r = pcall(f)
    say(label .. ": " .. (ok and ("ok " .. tostring(r)) or ("ERR " .. tostring(r))))
    return ok, r
end
local function methods(label, o)
    try("methods of " .. label, function()
        local t = {}
        for _, m in ipairs({}) do end
        local ms = o:getClass():getMethods()
        for i = 0, ms:size() - 1 do t[#t + 1] = ms:get(i):getName() end
        table.sort(t)
        local out, last = {}, nil
        for _, n in ipairs(t) do if n ~= last then out[#out + 1] = n; last = n end end
        return table.concat(out, " ")
    end)
end
local sm = getZomboidRadio():getScriptManager()
local list = sm:getChannelsList()
local ch
for i = 0, list:size() - 1 do if list:get(i):IsTv() then ch = list:get(i); break end end
methods("RadioScriptManager", sm)
methods("channel", ch)
try("getAiringBroadcast", function() return tostring(ch:getAiringBroadcast()) end)
try("getCurrentScript", function() return tostring(ch:getCurrentScript()) end)
try("getRadioScripts", function() return tostring(ch:getRadioScripts()) end)
try("getScripts", function() return tostring(ch:getScripts()) end)
try("getCategory", function() return tostring(ch:getCategory()) end)
try("isEmergency/Vanilla", function() return tostring(ch:isVanilla()) end)
try("radio disabled", function() return tostring(getZomboidRadio():getDisableBroadcasting()) end)
try("Sandbox radio", function() return tostring(SandboxVars.Radio) end)
try("getBroadcastDevices", function() return tostring(getZomboidRadio():getBroadcastDevicesCount()) end)
local n = 0
local function t() n = n + 1; if n == 10 then Events.OnTick.Remove(t); say("DONE") end end
Events.OnTick.Add(t)
