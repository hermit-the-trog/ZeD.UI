-- ZeDUI/tools/qa/gallery_b10_glasses.lua  (Nov 9 2026, QA; Nov 17 2026 rule fixed)
-- Prescription glasses blur the whole world in B42 unless the character really has the Short Sighted trait (measured
-- Nov 17: sharpness 74 with them on, 1089 off; the QA character logs "short sighted false"). So: a pair is worn only
-- for a short-sighted character; otherwise any worn prescription pair is taken off. Stays that way; the game quits
-- after the run. grep "ZEDQA gls".
local p = getPlayer()
local function say(s) print("ZEDQA gls " .. tostring(s)) end
local ss = false
pcall(function() ss = p:getCharacterTraits():get(CharacterTrait.SHORT_SIGHTED) == true end)
local on = false
if ss then
    local g = nil
    pcall(function() g = p:getInventory():AddItem("Base.Glasses_Prescription") end)
    if g then
        pcall(function() p:setWornItem(g:getBodyLocation(), g) end)
        on = true
    else say("ERR no glasses item") end
else
    pcall(function()
        local wi = p:getWornItems()
        local drop = {}
        for i = 0, wi:size() - 1 do
            local it = wi:get(i):getItem()
            if it and tostring(it:getFullType()):find("Glasses_Prescription", 1, true) then drop[#drop + 1] = it end
        end
        for _, it in ipairs(drop) do p:removeWornItem(it, false) end
    end)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
end
say("short sighted " .. tostring(ss) .. ", prescription glasses " .. (on and "on" or "off"))
local n = 0
local function later() n = n + 1; if n < 90 then return end; Events.OnTick.Remove(later); say("DONE") end
Events.OnTick.Add(later)
