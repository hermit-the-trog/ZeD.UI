-- ZeDUI/tools/qa/zedqa_stations.lua  (S124)
-- Crafting stations regression for the QA save. Copy to Zomboid/Lua/zedqa.lua
-- and bump zedqa.go. Spawns a Primitive Kiln, a Pottery Wheel and a Small
-- Plant Drying Rack around the character (build cheat, Q155), then checks the
-- vanilla entry point, the bench list, the lock hand-over, the rack data and
-- the crafting / build key toggles. Grep console.txt for ZEDQA.
-- The character must be on open ground, out of any vehicle.

local p = getPlayer()
local ST = ZeD.Stations
local function say(s) print("ZEDQA st " .. tostring(s)) end
local function W() return ZeD_WorldWindow.getWindow() end
p:setGodMod(true)

local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end

local function spawnNear(full, offsets)
    local info = findInfo(full)
    if not info then say("no info " .. full); return end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for _, o in ipairs(offsets) do
        p:setBuildCheat(true)
        local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
        b.buildCheat = true
        b.player = p:getPlayerNum()                   -- Q155: create() reads it
        local sq = getCell():getGridSquare(px + o[1], py + o[2], 0)
        local ok, valid = pcall(function() b.sq = sq; return b:isValid(sq) end)
        if ok and valid then
            pcall(function() b:create(px + o[1], py + o[2], 0, false, nil) end)
            p:setBuildCheat(false)
            say("spawned " .. full .. " at " .. (px + o[1]) .. "," .. (py + o[2]))
            return
        end
    end
    p:setBuildCheat(false)
    say("no room for " .. full)
end

local function find(name)
    for _, st in ipairs(ST.nearby(p, true)) do if st.name == name or st.kind == name then return st end end
end

local steps = {
    { 1, function()
        if p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end
        if not find("Primitive Kiln") then spawnNear("Base.Kiln_Small", { { 2, 0 }, { 3, 0 }, { 2, -2 } }) end
        if not find("Pottery Wheel") then spawnNear("Base.Pottery_Wheel", { { 2, 1 }, { 3, 2 }, { -2, 0 } }) end
        if not find("machine") then spawnNear("Base.Herb_Drying_Rack", { { -2, -2 }, { -1, -3 }, { -3, 1 }, { 0, 3 } }) end
    end },
    { 10, function()
        for _, st in ipairs(ST.nearby(p, true)) do say("near " .. st.kind .. " " .. st.name .. " d=" .. string.format("%.1f", st.dist)) end
        ISEntityUI.OpenWindow(p, find("Primitive Kiln").obj)
    end },
    { 50, function()
        local cur = ST.current(p)
        local data = W()._craftCache
        say("kiln bound=" .. tostring(cur and cur.name) .. " tab=" .. tostring(W()._activeTab) .. " recipes=" .. tostring(data and #data.recipes)
            .. " lock=" .. tostring(cur and cur.obj:getUsingPlayer() == p))
    end },
    { 60, function() W()._craftState.stDropdownOpen = true end },
    { 80, function()
        local wheel = find("Pottery Wheel")
        ST.pickRow(W()._craftState, p, { kind = "station", st = wheel })
        local kiln = find("Primitive Kiln")
        say("wheel bound=" .. tostring(ST.current(p) and ST.current(p).name) .. " kilnLockFreed=" .. tostring(kiln.obj:getUsingPlayer() == nil))
    end },
    { 100, function()
        ISEntityUI.OpenWindow(p, find("machine").obj)
    end },
    { 140, function()
        local st = ST.current(p)
        local d = st and st._md
        say("rack bound=" .. tostring(st and st.kind) .. " cap=" .. tostring(d and d.cap) .. " bag=" .. tostring(d and #d.bag) .. " running=" .. tostring(d and d.running))
        ISEntityUI.OpenHandcraftWindow(p, nil)
    end },
    { 170, function()
        say("craft key while showing -> tab=" .. tostring(W()._activeTab))
        ISEntityUI.OpenBuildWindow(p)
    end },
    { 200, function()
        say("build key -> tab=" .. tostring(W()._activeTab))
        ISEntityUI.OpenHandcraftWindow(p, nil, "*", false, getScriptManager():getCraftRecipe("FireBrick"))
    end },
    { 250, function()
        say("recipe hand-off -> tab=" .. tostring(W()._activeTab) .. " selected=" .. tostring(W()._craftState.selected) .. " bound=" .. tostring(ST.current(p) and ST.current(p).name))
        say("done")
    end },
}
local n, i = 0, 1
local function tick()
    n = n + 1
    while steps[i] and steps[i][1] <= n do
        local ok, err = pcall(steps[i][2])
        if not ok then say("step " .. i .. " failed: " .. tostring(err)) end
        i = i + 1
    end
    if not steps[i] then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
