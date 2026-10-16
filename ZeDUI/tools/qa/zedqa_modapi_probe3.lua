-- ZeDUI/tools/qa/zedqa_modapi_probe3.lua  (Oct 16 2026)
-- At the main menu: what a script object remembers about each time it was
-- defined (loadedScriptBodies), so duplicate items and recipes can be found
-- without reading files; and whether listFilesInModDirectory reaches a mod's
-- common folder. Read only. grep "ZEDQA m3".
local function say(s) print("ZEDQA m3 " .. tostring(s)) end
local function try(fn) local ok, r = pcall(fn); if ok then return r end; return "ERR " .. tostring(r) end
local sm = getScriptManager()
local it = sm:getItem("Base.ZeDQAWidget")
say("widget " .. tostring(it) .. " mod " .. tostring(try(function() return it:getModID() end)))
say("bodies count " .. tostring(try(function() return it:getLoadedScriptBodyCount() end)))
local b = try(function() return it:getLoadedScriptBodies() end)
if type(b) ~= "string" and b then
    for i = 0, b:size() - 1 do
        local e = b:get(i)
        local s = tostring(e)
        say("  body " .. i .. " type " .. type(e) .. " " .. string.sub(s:gsub("%s+", " "), 1, 160))
    end
else say("bodies " .. tostring(b)) end
-- how many items / recipes have more than one body
local function count(label, list)
    local n, multi, ex = 0, 0, {}
    for i = 0, list:size() - 1 do
        local o = list:get(i)
        n = n + 1
        local c = 0
        pcall(function() c = o:getLoadedScriptBodyCount() end)
        if c > 1 then multi = multi + 1; if #ex < 6 then ex[#ex + 1] = tostring(try(function() return o:getScriptObjectFullType() end)) .. "x" .. c end end
    end
    say(label .. " " .. n .. " multi " .. multi .. " [" .. table.concat(ex, " ; ") .. "]")
end
count("items", sm:getAllItems())
count("craftRecipes", sm:getAllCraftRecipes())
count("vehicles", sm:getAllVehicleScripts())
count("entities", sm:getAllGameEntities())
local r = sm:getAllCraftRecipes():get(0)
say("recipe0 " .. tostring(try(function() return r:getName() end)) .. " mod " .. tostring(try(function() return r:getModID() end)) .. " mod2 " .. tostring(try(function() return r:getModule():getName() end)))
for _, p in ipairs({ "../common/media/lua/client", "../common", "..", "../42/media/lua/client/ZeD" }) do
    local l = try(function() return listFilesInModDirectory("ZeD_UI", p) end)
    say("list " .. p .. " -> " .. (type(l) == "string" and l or tostring(l and l:size())))
end
say("cur load " .. tostring(try(function() return ScriptManager.getCurrentLoadFileMod() end)))
say("DONE")
