-- ZeD QA: hot-reload the watch anchor module + both organisms from Zomboid/Lua/hot_*.lua
local p = getPlayer()
local function readAll(name) local r = getFileReader(name, false); if not r then return nil end; local s, l = "", r:readLine(); while l do s = s .. l .. string.char(10); l = r:readLine() end; r:close(); return s end
local function tear(M) pcall(function() local i = M._instance; if i then i:removeFromUIManager() end end); M._instance = nil end
tear(ZeD.Dashboard); tear(ZeD.Watch)
for _, name in ipairs({ "hot_WatchPlates.lua", "hot_ZeD_Dashboard.lua", "hot_ZeD_Watch.lua" }) do
    local src = readAll(name)
    local fn, err = loadstring(src or "", name)
    if not fn then print("ZEDQA hot compile " .. name .. ": " .. tostring(err)) else local ok, e = pcall(fn); print("ZEDQA hot run " .. name .. " ok=" .. tostring(ok) .. " " .. tostring(e)) end
end
ZeD.Watch.install()
ZeD.Dashboard.install(); if p:getVehicle() then ZeD.Dashboard.show(p) end
print("ZEDQA hot done dash=" .. tostring(ZeD.Dashboard.getInstance() ~= nil) .. " watch=" .. tostring(ZeD.Watch.getInstance() ~= nil) .. " thermoAnchor=" .. tostring(ZeD.WatchPlates.digital_black.lcd.thermo ~= nil))
