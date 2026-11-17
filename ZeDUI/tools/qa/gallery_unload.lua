-- ZeDUI/tools/qa/gallery_unload.lua  (Nov 17 2026, QA): the gallery character's load under 20 kg for the shot scripts after
-- it in a manifest (Build: the QA character carries about 49 of 20 kg and 100 items, and the windows, the Heavy Load
-- moodle and the overload bubble showed it). Pair it with gallery_reload.lua, later in the same manifest.
--   * Everything not worn, held, on the belt, and not the first of a few things the shots use (a cigarette, a lighter or
--     matches, a flashlight, a water bottle, one food) is taken OUT of the inventory and out of the bags worn or held.
--     The things are kept in GAL_UNLOAD.stash with the container each came from (nothing is hidden or destroyed);
--     then they go back one at a time while the load stays at or under 17 kg, until it reaches 15 kg.
--   * Until gallery_reload.lua: the load (kg of max, items, the Heavy Load moodle) is logged once a second and whenever
--     it changes ("ZEDQA unl load ..."), with "OVER" past 19 kg; the pointer is parked once where no UI element covers
--     it and kept hidden (Mouse.setCursorVisible(false)) on every drawn frame.
--   * GAL (the mall lot's staging, gallery_v3_core.lua) is cleared if a stale one is left, so a script that picks the
--     mall lot or the QA home by it (gallery_b19_a.lua) takes the home.
-- grep "ZEDQA unl".
GAL_UNLOAD = GAL_UNLOAD or {}
local U = GAL_UNLOAD
U.p = getPlayer()
U.inv = U.p:getInventory()
function U.say(s) print("ZEDQA unl " .. tostring(s)) end

-- (summed from the items: the inventory's own weight is cached and reads 0 until the next player update, so a run
-- straight after load saw 0 kg and took nothing out)
function U.weight()
    local ok, w = pcall(function()
        local t = 0
        local items = U.inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if U.p:isEquipped(it) then t = t + it:getEquippedWeight() else t = t + it:getUnequippedWeight() end
        end
        return t
    end)
    return ok and w or 999
end
function U.count()
    local n = 0
    pcall(function()
        local items = U.inv:getItems()
        n = items:size()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if instanceof(it, "InventoryContainer") and U.p:isEquipped(it) then n = n + it:getInventory():getItems():size() end
        end
    end)
    return n
end
function U.heavy()
    -- (the Heavy Load moodle may not exist yet: a nil read threw a Java exception every second and failed each
    -- script's window; the game's own "heavy" flag is read instead)
    local ok, l = pcall(function() return (U.p:getInventoryWeight() > U.p:getMaxWeight()) and 1 or 0 end)
    return ok and l or -1
end
function U.line()
    local w = U.weight()
    return string.format("%.1f of %s kg, %d items, Heavy Load %s%s", w, tostring(U.p:getMaxWeight()), U.count(), tostring(U.heavy()),
        (w > 19) and " OVER" or "")
end

U.NEED = { "Cigarette", "Lighter", "Matches", "Flashlight", "Torch", "WaterBottle" }
function U.keep(it, need)
    if U.p:isEquipped(it) or U.p:isEquippedClothing(it) or U.p:isHandItem(it) then return true end
    if it:getAttachedSlot() and it:getAttachedSlot() > -1 then return true end
    local ft = it:getFullType()
    for _, pat in ipairs(U.NEED) do
        if not need[pat] and string.find(ft, pat, 1, true) then need[pat] = true; return true end
    end
    if not need.food and it:IsFood() then need.food = true; return true end
    return false
end
function U.lighten()
    if U.stash and #U.stash > 0 then U.say("a load is already taken out (" .. #U.stash .. " things); not again"); return end
    U.stash = {}
    local need, worn = {}, {}
    local items = U.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if U.keep(it, need) then
            if instanceof(it, "InventoryContainer") then worn[#worn + 1] = it:getInventory() end
        else U.stash[#U.stash + 1] = { it = it, c = U.inv } end
    end
    for _, bag in ipairs(worn) do
        local b = bag:getItems()
        for i = 0, b:size() - 1 do
            local it = b:get(i)
            if not U.keep(it, need) then U.stash[#U.stash + 1] = { it = it, c = bag } end
        end
    end
    for _, e in ipairs(U.stash) do pcall(function() e.c:Remove(e.it) end) end
    for _, e in ipairs(U.stash) do
        if U.weight() >= 8 then break end
        pcall(function() e.c:AddItem(e.it) end)
        if U.weight() > 10 then pcall(function() e.c:Remove(e.it) end) else e.back = true end
    end
    local out = 0
    for _, e in ipairs(U.stash) do if not e.back then out = out + 1 end end
    U.say("taken out of the inventory for the run: " .. out .. " things (kept in GAL_UNLOAD.stash)")
end

-- the pointer parked where no visible UI element covers it
U.PARK = { { 1, 0.5 }, { 0, 0.5 }, { 0.5, 1 }, { 0.5, 0 }, { 1, 0 }, { 0, 1 }, { 0.75, 1 }, { 0.25, 0 } }
function U.covered(x, y)
    local hit = false
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:isVisible() and e:getClass():getSimpleName() ~= "UIDebugConsole" then
                local ex, ey = e:getAbsoluteX(), e:getAbsoluteY()
                if x >= ex and y >= ey and x < ex + e:getWidth() and y < ey + e:getHeight() then hit = true end
            end
        end
    end)
    return hit
end
function U.park()
    local W, H = getCore():getScreenWidth(), getCore():getScreenHeight()
    local px, py = W - 3, math.floor(H / 2)
    for _, c in ipairs(U.PARK) do
        local x, y = math.floor(c[1] * (W - 6)) + 3, math.floor(c[2] * (H - 6)) + 3
        if not U.covered(x, y) then px, py = x, y; break end
    end
    pcall(function() Mouse.setXY(px, py) end)
    U.say("pointer parked at " .. px .. "," .. py .. " and hidden")
end

-- every drawn frame: the pointer hidden; once a second, or when it changes, the load
function U.watch()
    pcall(function() Mouse.setCursorVisible(false) end)
    local now = getTimestampMs()
    local l = U.line()
    local key = string.format("%.1f/%d", U.weight(), U.count())
    if key ~= U.lastKey or now - (U.lastAt or 0) >= 1000 then
        U.lastKey, U.lastAt = key, now
        U.say("load " .. l)
    end
end

if GAL then U.say("a stale GAL was left (the mall lot's staging): cleared, so the scripts after take the QA home"); GAL = nil end
pcall(function() U.cursorWas = Mouse.isCursorVisible() end)
U.say("before: " .. U.line())
local ok, e = pcall(U.lighten)
if not ok then U.say("ERR lighten: " .. tostring(e)) end
U.say("after: " .. U.line())
U.park()
if U.watching then Events.OnPreUIDraw.Remove(U.watch) end
Events.OnPreUIDraw.Add(U.watch)
U.watching = true
local n = 0
local function later()
    n = n + 1
    if n < 10 then return end
    Events.OnPreUIDraw.Remove(later)
    U.say("DONE")
end
Events.OnPreUIDraw.Add(later)
