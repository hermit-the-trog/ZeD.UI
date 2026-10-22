-- ZeDUI/tools/qa/zedqa_dress.lua  (Oct 21 2026)
-- Dresses a Workshop shot character for good, a few weeks into the apocalypse.
-- Director, Oct 21: "each character should be wearing pants, socks, shoes, a belt,
-- shirt, jacket, backpack, hat, something on their back. both belt spots, a watch
-- and various accessories." Looks are original: no signature look of the film
-- heroes the names parody.
--
-- The run puts a config table above this header:
--   ZEDQA_DRESS = {
--     name    = "Plizken",
--     wear    = { { "pants", { "Base.Trousers_Padded", "Base.Trousers_Denim" } }, ... },
--                 each place a list of candidates: the first that exists and fits is worn
--     belt    = { { "Base.HuntingKnife" }, { "Base.WalkieTalkie2" } }   the two belt slots
--     back    = { "Base.HuntingRifle", "Base.Shotgun" }                 slung on the back
--     hand    = "Base.BaseballBat"                                       in hand
--   }
-- What the character wore before (the random outfit the debug start gave it) is
-- taken off and thrown away, so nothing blocks a place. This is for the shot saves
-- only (Saves/Sandbox/ZeD-Shots-*): it is not put back.
-- Output: "ZEDQA dress ..." lines; the last is "ZEDQA dress DONE".
local C = ZEDQA_DRESS
local function say(s) print("ZEDQA dress " .. tostring(s)) end
if not C then say("ERR no ZEDQA_DRESS"); return end
local p = getPlayer()
if not p then say("ERR no player"); return end
local inv = p:getInventory()
local pn = p:getPlayerNum()
local SM = getScriptManager()

local function exists(ft)
    local ok, it = pcall(function() return SM:FindItem(ft) end)
    return ok and it ~= nil
end

-- 1. off with the old clothes (and anything hanging on the old belt or back)
local hb = getPlayerHotbar and getPlayerHotbar(pn)
if hb then
    for i, it in pairs(hb.attachedItems or {}) do
        pcall(function() hb:removeItem(it, false) end)
        pcall(function() inv:Remove(it) end)
    end
end
local old = {}
pcall(function()
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do old[#old + 1] = wi:get(i):getItem() end
end)
for _, it in ipairs(old) do
    pcall(function() p:removeWornItem(it, false) end)
    pcall(function() p:removeWornItem(it) end)
    pcall(function() inv:Remove(it) end)
end
pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
say("took off " .. #old .. " old things")

-- 2. on with the new: the first candidate that exists and whose place is free
local worn, missing = {}, {}
local function wearOne(label, cands)
    for _, ft in ipairs(cands) do
        if exists(ft) then
            local it = inv:AddItem(ft)
            if it then
                local busy = false
                pcall(function() busy = p:getWornItem(it:getBodyLocation()) ~= nil end)
                if busy then
                    inv:Remove(it)
                else
                    local ok = pcall(function() p:setWornItem(it:getBodyLocation(), it) end)
                    if ok then worn[#worn + 1] = label .. "=" .. ft; return it end
                    inv:Remove(it)
                end
            end
        end
    end
    missing[#missing + 1] = label
    return nil
end
for _, w in ipairs(C.wear or {}) do wearOne(w[1], w[2]) end
pcall(function() triggerEvent("OnClothingUpdated", p) end)
say("worn: " .. table.concat(worn, ", "))
if #missing > 0 then say("NOTE not worn (nothing fit): " .. table.concat(missing, ", ")) end

-- 3. the belt's two slots and the back: attached through the hotbar, as a player would
local function attach(cands, where)
    hb = getPlayerHotbar and getPlayerHotbar(pn)
    if not hb then say("NOTE no hotbar"); return false end
    pcall(function() hb:refresh() end)
    for _, ft in ipairs(cands) do
        if exists(ft) then
            local it = inv:AddItem(ft)
            if it then
                for i, slot in ipairs(hb.availableSlot or {}) do
                    if not hb.attachedItems[i] then
                        local fits = false
                        pcall(function()
                            if ZeD and ZeD.Belt and ZeD.Belt.fits then fits = ZeD.Belt.fits(hb, i, it)
                            else fits = slot.def.attachments[it:getAttachmentType()] ~= nil end
                        end)
                        local wantBack = (where == "back")
                        local isBack = tostring(slot.def and slot.def.type or ""):lower():find("back", 1, true) ~= nil
                        if fits and wantBack == isBack then
                            local ok = pcall(function() hb:attachItem(it, slot.def.attachments[it:getAttachmentType()], i, slot.def, false) end)
                            if ok and hb.attachedItems[i] == it then
                                say(where .. ": " .. ft .. " in slot " .. tostring(slot.def.type))
                                return true
                            end
                        end
                    end
                end
                inv:Remove(it)
            end
        end
    end
    say("NOTE " .. where .. ": nothing fit (" .. table.concat(cands, " / ") .. ")")
    return false
end
for _, b in ipairs(C.belt or {}) do attach(b, "belt") end
if C.back then attach(C.back, "back") end
pcall(function()
    local slots = {}
    for i, slot in ipairs(hb.availableSlot or {}) do slots[#slots + 1] = tostring(slot.def.type) .. (hb.attachedItems[i] and "*" or "") end
    say("hotbar slots: " .. table.concat(slots, " "))
end)

-- 4. in hand
if C.hand and exists(C.hand) then
    local w = inv:AddItem(C.hand)
    if w then
        p:setPrimaryHandItem(w)
        local both = false
        pcall(function() both = w:isRequiresEquippedBothHands() end)
        if both then p:setSecondaryHandItem(w) end
    end
end

-- 5. a few weeks on the road: worn clothes, dirt everywhere, blood here and there, two holes
local n = 0
pcall(function()
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:get(i):getItem()
        pcall(function() it:setCondition(math.max(1, math.floor(it:getConditionMax() * 0.7))) end)
    end
end)
for _, part in ipairs({ "LowerLeg_L", "LowerLeg_R", "UpperLeg_L", "UpperLeg_R", "Groin", "Torso_Lower", "Torso_Upper",
                        "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R", "Hand_L", "Hand_R", "Foot_L", "Foot_R" }) do
    pcall(function() local bp = BloodBodyPartType[part]; for _ = 1, 4 do p:addDirt(bp, nil, false) end; n = n + 1 end)
end
for _, part in ipairs({ "ForeArm_R", "Torso_Lower", "UpperLeg_R" }) do
    pcall(function() p:addBlood(BloodBodyPartType[part], false, false, false) end)
end
for _, part in ipairs({ "LowerLeg_L", "UpperArm_L" }) do
    pcall(function() p:addHole(BloodBodyPartType[part]) end)
end
pcall(function() p:resetModelNextFrame() end)
pcall(function() triggerEvent("OnClothingUpdated", p) end)
pcall(function() if hb then hb:refresh() end end)
say("worn in: dirt on " .. n .. " parts, blood on 3, holes in 2")
say(string.format("%s at %d,%d", tostring(C.name), math.floor(p:getX()), math.floor(p:getY())))
say("DONE")
