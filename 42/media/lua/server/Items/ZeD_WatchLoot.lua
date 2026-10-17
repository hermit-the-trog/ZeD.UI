-- ZeD-UI/42/media/lua/server/Items/ZeD_WatchLoot.lua
-- ============================================================================
-- Loot for the watches ZeD-UI adds (director, Oct 16 2026).
-- The steel Timez turns up wherever vanilla's Dress watch does, as often as it
-- does: in every loot list that names WristWatch_Left_DigitalDress, the Timez
-- goes in right after it with the same weight.
--
-- How vanilla's loot lists look: flat arrays of name, weight, name, weight ...
-- inside ProceduralDistributions, SuburbsDistributions, VehicleDistributions,
-- ClutterTables (desk and glove box junk) and BagsAndContainers. Some arrays are
-- shared by several lists, so each array is only touched once.
-- Runs on OnPreDistributionMerge: after vanilla filled its tables, before the
-- game merges them (Events from SuburbsDistributions.lua).
-- ============================================================================

local PAIRS = {
    -- { the vanilla item to follow, the item that joins it }
    { "WristWatch_Left_DigitalDress", "WristWatch_Left_DigitalTimez" },
}

local function addAfter(arr, done)
    if done[arr] then return 0 end
    done[arr] = true
    local added = 0
    for _, pr in ipairs(PAIRS) do
        local follow, join = pr[1], pr[2]
        -- look first, insert after: inserting while walking would shift the indexes
        local spots, already = {}, false
        for i = 1, #arr - 1 do
            local v = arr[i]
            if v == join or v == "Base." .. join then already = true end
            if (v == follow or v == "Base." .. follow) and type(arr[i + 1]) == "number" then spots[#spots + 1] = i end
        end
        if not already then
            for s = #spots, 1, -1 do          -- from the last spot back, so earlier spots keep their index
                local i = spots[s]
                table.insert(arr, i + 2, join)
                table.insert(arr, i + 3, arr[i + 1])
                added = added + 1
            end
        end
    end
    return added
end

-- every table reachable from t (loot lists nest: rooms -> containers -> items / junk)
local function walk(t, seen, done)
    if type(t) ~= "table" or seen[t] then return 0 end
    seen[t] = true
    local n = 0
    if type(t[1]) == "string" then n = n + addAfter(t, done) end
    for _, v in pairs(t) do
        if type(v) == "table" then n = n + walk(v, seen, done) end
    end
    return n
end

local function addWatchLoot()
    local seen, done, n = {}, {}, 0
    for _, root in ipairs({ ProceduralDistributions, SuburbsDistributions, VehicleDistributions, ClutterTables, BagsAndContainers }) do
        n = n + walk(root, seen, done)
    end
    print("[ZeD] Watch loot: the steel Timez joined " .. tostring(n) .. " loot lists")
end

Events.OnPreDistributionMerge.Add(addWatchLoot)
