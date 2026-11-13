-- ZeDUI/tools/qa/zedqa_qa_pickup.lua  (Oct 25 2026)
-- Maintenance for the ZeD-QA save: everything lying loose on the ground round the
-- character (two squares each way) goes back into the character's inventory. The
-- controller test drops a row's item with A; when its focus landed on the wrong rows
-- (Oct 25 2026, the windows left on another tab by the test before it) it dropped the
-- character's own things, 27 of them, and later scripts saw them as ground containers.
-- Containers standing on the ground (the test crate, the deep run's crate) are not
-- touched. Lists what it picked up. grep "ZEDQA pu".
local p = getPlayer()
local inv = p:getInventory()
local function say(s) print("ZEDQA pu " .. tostring(s)) end
local cell = getCell()
local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
local got, names = 0, {}
for dx = -2, 2 do
    for dy = -2, 2 do
        local sq = cell:getGridSquare(x0 + dx, y0 + dy, z0)
        local wobs = sq and sq:getWorldObjects()
        if wobs and wobs:size() > 0 then
            local list = {}
            for i = 0, wobs:size() - 1 do list[#list + 1] = wobs:get(i) end
            for _, wio in ipairs(list) do
                local it = wio:getItem()
                if it then
                    local ok = pcall(function()
                        sq:transmitRemoveItemFromSquare(wio)
                        it:setWorldItem(nil)
                        inv:AddItem(it)
                    end)
                    if ok then got = got + 1; names[#names + 1] = it:getDisplayName() end
                end
            end
        end
    end
end
say("picked up " .. got .. ": " .. table.concat(names, ", "))
say("inventory now " .. inv:getItems():size() .. " items")
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); say("DONE") end
Events.OnTick.Add(later)
