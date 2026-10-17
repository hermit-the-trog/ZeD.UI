-- ZeD QA (Oct 16 2026): the belt's per-slot strap materials. Wears four loadouts in turn (leather belt + brown
-- holster; ALICE camo webbing + ALICE pack + taped holster; rope belt + frame pack + hide holster; breathing pack),
-- screenshots the belt each time, then takes it all off again.
local p = getPlayer(); local inv = p:getInventory()
local function say(s) print("ZEDQA straps " .. tostring(s)) end
local function mk(ft) if instanceItem then return instanceItem(ft) end; return InventoryItemFactory.CreateItem(ft) end
local made = {}
local function wearAll(list)
    for _, it in ipairs(made) do pcall(function() p:removeWornItem(it) end); pcall(function() inv:Remove(it) end) end
    made = {}
    for _, ft in ipairs(list) do
        local it = mk(ft)
        if it then
            inv:AddItem(it)
            -- worn as vanilla's ISWearClothing does: a bag (any container that can be equipped) by canBeEquipped(),
            -- clothing by its body location
            local ok, e = pcall(function()
                local loc = nil
                if instanceof(it, "InventoryContainer") and it:canBeEquipped() and it:canBeEquipped() ~= "" then loc = it:canBeEquipped()
                else loc = it:getBodyLocation() end
                p:setWornItem(loc, it)
            end)
            if not ok then say("could not wear " .. ft .. ": " .. tostring(e)) end
            made[#made + 1] = it
        else say("no item " .. ft) end
    end
    pcall(function() local hb = getPlayerHotbar(0); if hb then hb:refresh() end end)
end
local LOADS = {
    { "civilian", { "Base.Belt2", "Base.HolsterSimple_Brown" } },
    { "military", { "Base.Bag_ALICE_BeltSus_Camo", "Base.Bag_ALICEpack_Army", "Base.Holster_DuctTape" } },
    { "makeshift", { "Base.RopeBelt", "Base.Bag_CraftedFramepack_Large", "Base.Holster_Hide" } },
    { "firefighter", { "Base.SCBA" } },
    { "olive", { "Base.Bag_ALICE_BeltSus" } },
}
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
-- what the player wears now that gives slots: put aside for the test, back after
local aside = {}
at(5, function()
    setGameSpeed(1)
    local worn = p:getWornItems()
    for i = worn:size() - 1, 0, -1 do
        local it = worn:get(i):getItem()
        if it and it:getAttachmentsProvided() then aside[#aside + 1] = { it, worn:get(i):getLocation() } end
    end
    for _, a in ipairs(aside) do p:removeWornItem(a[1]) end
    say("put aside " .. #aside)
end)
local t = 20
for _, L in ipairs(LOADS) do
    at(t, function() wearAll(L[2]) end)
    at(t + 90, function()
        local h = ZeD.Belt and ZeD_BeltHUD and nil
        pcall(function() getCore():TakeFullScreenshot("zqa_straps_" .. L[1] .. ".png") end)
        -- what the belt made of it: each slot's material, the waist, the closure
        pcall(function()
            local hud = ZeD.Belt.getHUD()
            local parts = {}
            for _, bx in ipairs(hud._boxes or {}) do
                if bx.kind == "slot" then
                    local t = bx.s and bx.s.slot and bx.s.slot.slotType or "?"
                    parts[#parts + 1] = t .. "=" .. tostring(ZeD.Belt.materialFor(t, hud._prov or {}))
                end
            end
            local worn = {}
            local wi = p:getWornItems()
            for i = 0, wi:size() - 1 do local it = wi:get(i):getItem(); if it then worn[#worn + 1] = it:getType() end end
            say(L[1] .. " worn " .. table.concat(worn, ","))
            say(L[1] .. " slots " .. table.concat(parts, " ") .. " | waist=" .. tostring(hud._waist) .. " closure=" ..
                tostring(hud._closure and hud._closure.kind))
        end)
        say(L[1] .. " shot")
    end)
    t = t + 110
end
at(t, function()
    wearAll({})
    for _, a in ipairs(aside) do pcall(function() p:setWornItem(a[2], a[1]) end) end
    pcall(function() local hb = getPlayerHotbar(0); if hb then hb:refresh() end end)
    say("restored; DONE")
end)
local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
