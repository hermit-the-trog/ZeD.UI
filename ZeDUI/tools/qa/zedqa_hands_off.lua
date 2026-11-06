-- ZeDUI/tools/qa/zedqa_hands_off.lua  (Nov 5 2026, QA; punch list 54): the transfer that fails with Hands-On Interactions on, with
-- ZeD off (zedqa_off_run.ps1 -ModList with HandsOnInteractionsIso; the probe mod carries the bridge). A razor in a bag, moved to the
-- main inventory by the game's own action through the game's queue, then a beard trim the game's way. If the callFrame error comes
-- here, ZeD has no part in it. grep "ZEDQA hof"; the runner's output lists the console's errors.
local function say(s) print("ZEDQA hof " .. tostring(s)) end
local p = getPlayer()
local inv = p:getInventory()
local bag = inv:AddItem("Base.Bag_Schoolbag")
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local razor
add(300, function()
    pcall(function() p:getHumanVisual():setBeardModel("Chops") end)
    razor = bag:getItemContainer():AddItem("Base.Razor")
    say("razor in the bag " .. tostring(razor ~= nil))
    local ok, e = pcall(function() ISTimedActionQueue.add(ISInventoryTransferAction:new(p, razor, bag:getItemContainer(), inv)) end)
    say("transfer queued: " .. tostring(ok) .. " " .. tostring(e or ""))
end)
add(3000, function()
    say("the razor is in " .. tostring(razor and razor:getContainer() == inv and "the main inventory" or "the bag still"))
    local ok, e = pcall(function() ISCharacterScreen.onTrimBeard(p, "Goatee") end)
    say("the game's onTrimBeard: " .. tostring(ok) .. " " .. tostring(e or ""))
end)
add(4000, function()
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
