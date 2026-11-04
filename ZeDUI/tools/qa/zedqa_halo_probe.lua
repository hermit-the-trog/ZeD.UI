-- ZeDUI/tools/qa/zedqa_halo_probe.lua  (Nov 4 2026, QA; the director: overhead text into a bubble plus a Messages log)
-- Can ZeD catch the game's overhead "halo" lines? In game on the QA save:
--   1. HaloTextHelper's Lua-visible functions replaced by wrappers (addText, addGoodText, addBadText,
--      addTextWithArrow): does the table take the assignment, and does a call through the global reach the wrapper
--      (as every vanilla Lua caller does, e.g. ISWorldObjectContextMenu's "not safe to sleep")?
--   2. a caught line NOT passed on: does the game still draw it? (picture 2 should show no red line)
--   3. a line passed on: drawn as usual (picture 3)
--   4. XP: Events.AddXP fires on player:getXp():AddXP; with the game's "show crafting XP" option on, a picture
--      (the engine's halo); with it off, a picture (none expected)
-- Everything put back at the end. grep "ZEDQA hal".
local function say(s) print("ZEDQA hal " .. tostring(s)) end
local core = getCore()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_hal_" .. n .. ".png") end); say("shot " .. n) end
local p = getPlayer()
local H = HaloTextHelper
local names = { "addText", "addGoodText", "addBadText", "addTextWithArrow" }
local orig, seen = {}, {}
local passOn = true
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local xpEvents = {}
local function onXP(who, perk, amount) xpEvents[#xpEvents + 1] = tostring(perk) .. " " .. tostring(amount) end

step(30, function()
    say("HaloTextHelper is a " .. type(H))
    for _, k in ipairs(names) do
        orig[k] = H[k]
        local ok, err = pcall(function()
            H[k] = function(...)
                local a = { ... }
                seen[#seen + 1] = k .. ": " .. tostring(a[2]) .. (a[3] and (" | " .. tostring(a[3])) or "")
                if passOn then return orig[k](...) end
            end
        end)
        say(string.format("%s: assignment %s%s; reads back as wrapper %s", k, ok and "taken" or "refused", ok and "" or (" (" .. tostring(err) .. ")"), tostring(H[k] ~= orig[k])))
    end
    Events.AddXP.Add(onXP)
end)
-- 2: caught and not passed on
step(10, function()
    passOn = false
    HaloTextHelper.addBadText(p, "QA caught: should NOT show")
end)
step(20, function() say("caught (not passed): " .. tostring(seen[#seen])); shot("2_caught_not_drawn") end)
-- 3: passed on
step(10, function()
    passOn = true
    HaloTextHelper.addBadText(p, "QA passed on: should show")
end)
step(20, function() say("caught (passed on): " .. tostring(seen[#seen])); shot("3_passed_on_drawn") end)
-- 4: XP, the game's option on, then off
step(200, function()
    say("show crafting XP option was " .. tostring(core:getOptionShowCraftingXP()))
    keepXP = core:getOptionShowCraftingXP()
    core:setOptionShowCraftingXP(true)
    p:getXp():AddXP(Perks.Carpentry, 5)
end)
step(20, function() shot("4_xp_option_on") end)
step(200, function()
    core:setOptionShowCraftingXP(false)
    p:getXp():AddXP(Perks.Carpentry, 5)
end)
step(20, function() shot("5_xp_option_off") end)
step(60, function()
    say("AddXP events seen: " .. #xpEvents .. " (" .. table.concat(xpEvents, "; ") .. ")")
    say("halo calls seen through Lua: " .. #seen)
    for i, s in ipairs(seen) do say("  " .. i .. " " .. s) end
    core:setOptionShowCraftingXP(keepXP == true)
    for _, k in ipairs(names) do pcall(function() H[k] = orig[k] end) end
    Events.AddXP.Remove(onXP)
    say("put back; DONE")
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
