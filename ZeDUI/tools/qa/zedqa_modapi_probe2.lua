-- ZeDUI/tools/qa/zedqa_modapi_probe2.lua  (Oct 16 2026)
-- At the main menu: how far listFilesInModDirectory reaches (sub folders,
-- the 42 / common split), the loaded Lua file list, and reading a file in a
-- mod by its relative path. Read only. grep "ZEDQA m2".
local function say(s) print("ZEDQA m2 " .. tostring(s)) end
local function try(fn) local ok, r = pcall(fn); if ok then return r end; return "ERR " .. tostring(r) end
local function show(label, r)
    if type(r) == "string" then say(label .. " -> " .. r); return end
    local n = r and r.size and r:size() or -1
    local s = {}
    for i = 0, math.min(n, 6) - 1 do s[#s + 1] = tostring(r:get(i)) end
    say(label .. " -> " .. n .. " [" .. table.concat(s, " ; ") .. "]")
end
for _, p in ipairs({ "42", "42/", "42/media", "42/media/lua/client/ZeD", "common", "42/media/lua/client/ZeD/Input", "media/lua/client/ZeD" }) do
    show("list(ZeD_UI, " .. p .. ")", try(function() return listFilesInModDirectory("ZeD_UI", p) end))
end
say("loaded lua count " .. tostring(try(function() return getLoadedLuaCount() end)))
local n = try(function() return getLoadedLuaCount() end)
if type(n) == "number" then
    for i = 0, math.min(n, 5) - 1 do say("  loaded " .. tostring(try(function() return getLoadedLua(i) end))) end
    for i = n - 3, n - 1 do say("  loaded " .. tostring(try(function() return getLoadedLua(i) end))) end
end
for _, p in ipairs({ "media/lua/client/ZeD/Tokens.lua", "42/media/lua/client/ZeD/ContainerControls.lua", "media/lua/client/ZeD/ContainerControls.lua", "mod.info" }) do
    local r = try(function() return getModFileReader("ZeD_UI", p, false) end)
    say("getModFileReader(ZeD_UI, " .. p .. ") -> " .. tostring(r ~= nil and type(r) ~= "string") .. (type(r) == "string" and (" " .. r) or ""))
    if r and type(r) ~= "string" then pcall(function() r:close() end) end
end
say("DONE")
