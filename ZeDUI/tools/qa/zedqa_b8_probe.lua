-- ZeDUI/tools/qa/zedqa_b8_probe.lua (Nov 8 2026, QA): what the game (42.21) gives Lua for the beta 8 hidden facts: getReadLiterature and the TV schedule. grep "ZEDQA b8pr".
local function say(s) print("ZEDQA b8pr " .. tostring(s)) end
local p = getPlayer()
local function try(label, f)
    local ok, r = pcall(f)
    say(label .. ": " .. (ok and ("ok " .. tostring(r)) or ("ERR " .. tostring(r))))
    return ok, r
end
local lit
try("getReadLiterature", function() lit = p:getReadLiterature(); return tostring(lit and lit:getClass() and lit:getClass():getName()) end)
try("size", function() return lit:size() end)
try("keySet", function() local k = lit:keySet(); return tostring(k:getClass():getName()) .. " size " .. tostring(k:size()) end)
try("keySet:iterator", function() return tostring(lit:keySet():iterator()) end)
try("keySet:toArray", function() local a = lit:keySet():toArray(); return tostring(a) .. " n " .. tostring(a:size() or #a) end)
try("isEmpty", function() return tostring(lit:isEmpty()) end)
try("containsKey", function() return tostring(lit:containsKey("x")) end)
try("contains", function() return tostring(lit:contains("x")) end)
try("get(0)", function() return tostring(lit:get(0)) end)
try("iterator", function() return tostring(lit:iterator()) end)
try("pairs", function() local n = 0; for k, v in pairs(lit) do n = n + 1 end; return n end)
try("values", function() return tostring(lit:values()) end)
try("entrySet:iterator", function() return tostring(lit:entrySet():iterator()) end)
try("getAlreadyReadPages", function() return tostring(p:getAlreadyReadPages("Base.BookFirstAid1")) end)
local R = getZomboidRadio()
try("radio", function() return tostring(R) end)
local sm
try("scriptManager", function() sm = R:getScriptManager(); return tostring(sm) end)
try("now", function() return tostring(sm:getCurrentTimeStamp()) end)
local list
try("channels", function() list = sm:getChannelsList(); return list:size() end)
local tv, withScript = 0, 0
try("scan", function()
    for i = 0, list:size() - 1 do
        local ch = list:get(i)
        if ch:IsTv() then
            tv = tv + 1
            local sc = ch:getCurrentScript()
            if sc then withScript = withScript + 1 end
            if i < 6 then say("ch " .. tostring(ch:GetName()) .. " tv " .. tostring(ch:IsTv()) .. " script " .. tostring(sc)) end
        end
    end
    return "tv " .. tv .. " withScript " .. withScript
end)
try("channel names", function() local t = {}; for i = 0, math.min(list:size(), 30) - 1 do local ch = list:get(i); t[#t + 1] = tostring(ch:GetName()) .. (ch:IsTv() and "(tv)" or "") end; return table.concat(t, ", ") end)
try("getChannelsList type", function() return tostring(list:getClass():getName()) end)
try("scripts of channel 0", function() local ch = list:get(0); return tostring(ch:getCurrentScript()) .. " / " .. tostring(ch:getCategory()) end)
try("F.schedule", function() local s = ZeD.Finds and ZeD.Finds.schedule and ZeD.Finds.schedule(); return tostring(s and #s) end)
local n = 0
local function t() n = n + 1; if n == 10 then Events.OnTick.Remove(t); say("DONE") end end
Events.OnTick.Add(t)
