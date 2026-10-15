-- ZeD QA: the belt (hands + hotbar). Copy to Zomboid/Lua/zedqa.lua and bump
-- zedqa.go. Wears a belt and a holster, puts a bat on the back, a hammer and a
-- knife on the belt and a pistol in the holster (no animation), then prints
-- every slot and where the belt sits. QA save only.
local p = getSpecificPlayer(0)
local inv = p:getInventory()
local function get(t) return inv:getFirstTypeRecurse(t) or inv:AddItem("Base." .. t) end
for _, t in ipairs({ "Belt2", "HolsterSimple" }) do
    local it = get(t)
    if it and not p:isEquippedClothing(it) then p:setWornItem(it:getBodyLocation(), it) end
end
local hb = getPlayerHotbar(0)
hb:refresh()
local want = { Back = "BaseballBat", SmallBeltLeft = "Hammer", SmallBeltRight = "HuntingKnife", HolsterRight = "Pistol" }
for i, s in ipairs(hb.availableSlot) do
    local t = want[s.slotType]
    if t and not hb.attachedItems[i] then
        local it = get(t)
        if it and not hb:isItemAttached(it) and ZeD.Belt.fits(hb, i, it) then
            hb:attachItem(it, s.def.attachments[it:getAttachmentType()], i, s.def, false)
        end
    end
end
get("HandTorch"); get("Screwdriver")
for i, s in ipairs(hb.availableSlot) do
    print("ZEDQA belt slot " .. i .. " " .. tostring(s.slotType) .. " key=" .. tostring(ZeD.Belt.keyLabel(i)) ..
        " item=" .. tostring(hb.attachedItems[i] and hb.attachedItems[i]:getType()))
end
local hud = ZeD.Belt.getHUD()
print("ZEDQA belt hud x=" .. tostring(hud and hud:getAbsoluteX()) .. " y=" .. tostring(hud and hud:getAbsoluteY()) ..
    " w=" .. tostring(hud and hud:getWidth()) .. " vanilla bar x=" .. tostring(hb:getX()))
