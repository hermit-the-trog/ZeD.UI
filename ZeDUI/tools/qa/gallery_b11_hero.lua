-- ZeDUI/tools/qa/gallery_b11_hero.lua  (Nov 11 2026, QA): run before gallery_v3_zed.lua: takes only its hero section with
-- ONE source open per window (punch list 161), the inventory as a list. gallery_v3_teardown.lua clears GAL_ONLY; this
-- clears GAL_ONE_SOURCE after the hero shots through gallery_b11_hero_end.lua. grep "ZEDQA b11h".
GAL_ONLY = { hero = true }
GAL_ONE_SOURCE = true
print("ZEDQA b11h hero, one source")
-- a half-full water bottle in the inventory (blue level cells beside the wielded item's five status cells)
pcall(function()
    local it = getPlayer():getInventory():AddItem("Base.WaterBottle")
    if it and it:getFluidContainer() then
        local fc = it:getFluidContainer(); fc:Empty(); fc:addFluid(Fluid.Water, fc:getCapacity() * 0.6)
        print("ZEDQA b11h water bottle " .. tostring(fc:getAmount()) .. "/" .. tostring(fc:getCapacity()))
    else print("ZEDQA b11h no bottle") end
end)local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA b11h DONE") end
Events.OnTick.Add(later)
