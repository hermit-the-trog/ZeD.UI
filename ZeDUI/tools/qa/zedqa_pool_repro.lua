-- ZeDUI/tools/qa/zedqa_pool_repro.lua  (Nov 5 2026, QA; the report to The Indie Stone): no mods but the bridge. Reads Lua/zedqa_pool_mode.txt:
-- "control" (no bad call), "poison" (one hasTag with a string in a pcall), "check" (poison with the pool's own check on). A razor in
-- the main inventory and a beard, then the game's own onTrimBeard. grep "ZEDQA pol".
local function say(s) print("ZEDQA pol " .. tostring(s)) end
local r = getFileReader("zedqa_pool_mode.txt", false)
local mode = r and r:readLine() or "control"; if r then r:close() end
say("mode " .. tostring(mode))
local p = getPlayer()
local inv = p:getInventory()
local razor = inv:AddItem("Base.Razor")
pcall(function() p:getHumanVisual():setBeardModel("Chops") end)
local item = inv:getItems():get(0)
say("items:get(0) is " .. tostring(item and item:getFullType()))
if mode == "check" then
    say("debug option set: " .. tostring(pcall(function() getDebugOptions():setBoolean("Checks.ObjectPoolContains", true) end)))
    say("debug option reads: " .. tostring(select(2, pcall(function() return getDebugOptions():getBoolean("Checks.ObjectPoolContains") end))))
end
if mode ~= "control" then
    print("ZEDQA pol pcall:", pcall(function() return item:hasTag("not a tag") end))
end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(1500, function()
    local ok, e = pcall(function() ISCharacterScreen.onTrimBeard(p, "Goatee") end)
    say("onTrimBeard: " .. tostring(ok) .. " " .. tostring(e or ""))
end)
add(5000, function()
    say("the beard now: " .. tostring(p:getHumanVisual():getBeardModel()))
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
