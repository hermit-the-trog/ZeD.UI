-- ZeDUI/tools/qa/perf_hotold.lua  (Oct 22 2026)
-- Same-session before / after for the drawing-cost work: loads the files of the drawing code
-- AS THEY WERE (copies the runner's caller put in Zomboid/Lua/perfold_<name>.lua) over the
-- running ones, so perf_capture.lua can take the same scenes again with the old drawing in the
-- same world (the stage's random loot, icons, radio presets and fuel stay the same). The module
-- tables are kept (InventoryRenderer's is reused rather than replaced, so the windows see the old
-- functions); the dashboard is rebuilt on its old class. Not part of the regression manifest.
-- Set PERF_CAP_PREFIX = "pco" for the next perf_capture.lua. "ZEDQA pho ... DONE".
local function say(s) print("ZEDQA pho " .. tostring(s)) end
local NL = string.char(10)
local function readAll(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local parts = {}
    local l = r:readLine()
    while l do parts[#parts + 1] = l; l = r:readLine() end
    r:close()
    return table.concat(parts, NL)
end
local FILES = { "Tr", "Scale", "Atoms", "ZeD_PixelParts", "ZeD_Plate", "ZeD_TabPx", "ContainerControls", "InventoryRenderer", "ZeD_Belt",
                "ZeD_RadioOps", "ZeD_Dashboard" }
local ok_all = true
for _, n in ipairs(FILES) do
    local src = readAll("perfold_" .. n .. ".lua")
    if not src then
        say("ERR no perfold_" .. n .. ".lua"); ok_all = false
    else
        if n == "InventoryRenderer" then
            src = src:gsub("ZeD%.InventoryRenderer = {}", "ZeD.InventoryRenderer = ZeD.InventoryRenderer or {}", 1)
        end
        local fn, err = loadstring(src, n)
        if not fn then say("ERR compile " .. n .. ": " .. tostring(err)); ok_all = false
        else
            local ok, e = pcall(fn)
            say("loaded " .. n .. " ok=" .. tostring(ok) .. (ok and "" or (" " .. tostring(e))))
            if not ok then ok_all = false end
        end
    end
end
-- the ZeD classes' lean draw calls (Overrides/TextScale.lua) taken off: the old ISUIElement path again
local nLean = 0
if ZeD.LeanDraw then
    for k, cls in pairs(_G) do
        if type(cls) == "table" and type(k) == "string" and k:sub(1, 4) == "ZeD_" and rawget(cls, "Type") == k then
            for m, f in pairs(ZeD.LeanDraw) do
                if rawget(cls, m) == f then cls[m] = ISUIElement[m]; nLean = nLean + 1 end
            end
        end
    end
end
say("lean draw calls taken off: " .. nLean .. " | LeanDraw " .. tostring(ZeD.LeanDraw ~= nil) .. " | ZeD_Panel.drawRect raw "
    .. tostring(rawget(ZeD_Panel, "drawRect")) .. " lean " .. tostring(ZeD.LeanDraw and ZeD.LeanDraw.drawRect))
-- the dashboard on the old class
pcall(function()
    local D = ZeD.Dashboard
    local i = D._instance
    if i then i:removeFromUIManager() end
    D._instance = nil
    D.install()
    local p = getPlayer()
    if p and p:getVehicle() then D.show(p) end
end)
-- the belt on the old methods (same class table): its kept layout dropped
pcall(function() local h = ZeD.Belt.getHUD(); if h then h._lk = nil end end)
PERF_CAP_PREFIX, PERF_CAP_TAG, PERF_CEN_TAG = "pco", "pcap2", "pcen2"
say("old drawing loaded: " .. tostring(ok_all))
-- (DONE on a later frame: the runner counts a script's lines only after the bridge has said it ran it)
local waitN = 0
local function later()
    waitN = waitN + 1
    if waitN < 30 then return end
    Events.OnRenderTick.Remove(later)
    say("DONE")
end
Events.OnRenderTick.Add(later)
