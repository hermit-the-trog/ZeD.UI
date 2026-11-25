-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SmartAttach.lua
-- ============================================================================
-- SMART ATTACH (smart attach, the director, Nov 24 2026). Client.
--
-- ZeD setup's switch "Attach looted tools and weapons" (Settings.lua, id "smartAttach"; on in the Access preset, off
-- in Vanilla and Plus and in Lite) does two things:
--
-- 1. LOOTED THINGS GO ON AN EMPTY SLOT. A plain take (Loot all, the card's Grab, pad X on a World window row, the
--    double-click) of something the game lets hang on the hotbar (a hammer, a screwdriver, a bat) puts it on an EMPTY
--    slot after the take: SA.after(playerObj, items), called once by each take. The slot is the first that fits in
--    the game's own order, the one its "Attach to" menu offers (ISHotbar.doMenuFromInventory: hotbar.availableSlot,
--    slot.def.attachments[item:getAttachmentType()], the Back slot's bag replacements). Never a slot that holds
--    something, never a swap; one thing per empty slot per take (two hammers: the first goes on the belt, the second
--    stays in the bag). The attach is the game's own action, ISAttachItemHotbar, queued after the take's own transfer,
--    so it costs the usual time. Only a thing with a take queued for it attaches (a refused move, a heavy thing put
--    in the hands: nothing). A drag, Move to, Put in, Transfer all and Same type never call it.
--    Left alone: favorites, broken things, things in the hands or worn, bags, corpses and heavy things.
--    A thing taken into a worn bag comes to the main inventory first (the game's attach asks for it there,
--    ISAttachItemHotbar:isValid; its own Attach to menu moves it the same way, transferIfNeeded).
--
-- 2. A SPARE TO HAND. When the weapon in his hands breaks (the game's OnPlayerAttackFinished, after each swing; in
--    multiplayer the break may reach the client a moment later, so a swing that did not break it is looked at again
--    for one second), the most worn spare he carries comes to hand by the game's own equip
--    (ISInventoryPaneContextMenu.equipWeapon: ISEquipWeaponAction, two hands for a two-handed weapon). Looked for on
--    his attached slots first, then in his main inventory (not inside bags: a bag's weapon is not "at hand").
--    Same weapon category first, then any melee weapon when the broken one was melee; a firearm only for a firearm.
--    Among those, the most worn (lowest condition for its maximum) that is not broken, so the good ones wait
--    (the director: use them up until they break); a tie goes to the attached slot. Not in a vehicle, not while
--    aiming a firearm, not when the hands already hold something else.
-- ============================================================================

ZeD = ZeD or {}
ZeD.SmartAttach = ZeD.SmartAttach or {}
local SA = ZeD.SmartAttach

--- The switch is on (ZeD setup, Attach looted tools and weapons), and ZeD is not in safe mode.
function SA.on()
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    local S = ZeD.Settings
    if not (S and S.smartAttachOn) then return false end
    local ok, v = pcall(S.smartAttachOn)
    return ok and v == true
end

-- ----------------------------------------------------------------------------
-- 1. LOOTED THINGS ON AN EMPTY SLOT
-- ----------------------------------------------------------------------------

-- The take queued for this item (the game's transfer action), or nil when none is waiting.
local function queuedTake(queue, item)
    for _, a in ipairs(queue or {}) do
        if a.item == item and a.destContainer ~= nil then return a end
    end
    return nil
end

-- True for a thing smart attach leaves alone (the brief's list).
local function skipped(playerObj, item)
    if not item.getAttachmentType or item:getAttachmentType() == nil then return true end
    if item:isFavorite() or item:isBroken() or item:isEquipped() then return true end
    if playerObj:isEquipped(item) then return true end
    if instanceof(item, "InventoryContainer") then return true end   -- a whole bag
    if item.isHumanCorpse and item:isHumanCorpse() then return true end
    if item.isAnimalCorpse and item:isAnimalCorpse() then return true end
    if isForceDropHeavyItem and isForceDropHeavyItem(item) then return true end
    return false
end

-- The hotbar's slot numbers in order (the game's own order, as its Attach to menu walks them).
local function slotOrder(hotbar)
    local order = {}
    for i in pairs(hotbar.availableSlot or {}) do order[#order + 1] = i end
    table.sort(order)   -- (a handful of slots: the recursive sort is fine here)
    return order
end
SA._slotOrder = slotOrder   -- (the test sim's way in)

--- The first EMPTY slot this item fits, not one in `taken`: slotIndex, model slot, slot def; nil when none.
--- The game's rule (ISHotbar.doMenuFromInventory, canBeAttached): the slot's def lists the item's attachment type;
--- on the Back slot a worn bag can move it (replacements), and "null" means it cannot go there at all.
function SA.slotFor(hotbar, item, taken)
    local atype = item:getAttachmentType()
    local repl = hotbar.replacements or {}
    if repl[atype] == "null" then return nil end
    for _, i in ipairs(slotOrder(hotbar)) do
        local s = hotbar.availableSlot[i]
        local def = s and s.def
        local model = def and def.attachments and def.attachments[atype]
        if model and not (hotbar.attachedItems or {})[i] and not taken[i] then
            if def.name == "Back" and repl[atype] then model = repl[atype] end
            if model ~= "null" then return i, model, def end
        end
    end
    return nil
end

--- After a plain take: each item that can hang on an empty slot is attached there by the game's own action, queued
--- after the take's transfer. items: the list the take moved. Returns how many attaches were queued.
function SA.after(playerObj, items)
    if not (playerObj and items and #items > 0) or not SA.on() then return 0 end
    if playerObj.getVehicle and playerObj:getVehicle() then return 0 end   -- (seated: the game attaches nothing)
    local hotbar = getPlayerHotbar and getPlayerHotbar(playerObj:getPlayerNum())
    if not (hotbar and hotbar.availableSlot) then return 0 end
    local q = ISTimedActionQueue.getTimedActionQueue(playerObj)
    local queue = q and q.queue
    local mainInv = playerObj:getInventory()
    local taken, n = {}, 0
    for _, item in ipairs(items) do
        local take = queuedTake(queue, item)
        if take and not skipped(playerObj, item) and not (hotbar.isInHotbar and hotbar:isInHotbar(item)) then
            local idx, model, def = SA.slotFor(hotbar, item, taken)
            if idx then
                taken[idx] = true
                -- into a worn bag: to the main inventory first, where the game's attach looks for it
                if take.destContainer ~= mainInv then
                    local hop = ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, take.destContainer, mainInv)
                    hop._zedApart = true   -- (the player's own move: Put things back never counts it, ZeD_PutBack.lua)
                    ISTimedActionQueue.add(hop)
                end
                local act = ISAttachItemHotbar:new(playerObj, item, model, idx, def)
                act._zedApart = true
                act._zedSmartAttach = true   -- (QA reads this on the queued action)
                -- the belt or back animation, set as the action starts (the game's attachItem sets it as it queues;
                -- with several queued the last would win)
                local baseStart = act.start
                act.start = function(self)
                    if def.animset and self.character.SetVariable then self.character:SetVariable("AttachAnim", def.animset) end
                    return baseStart(self)
                end
                -- a slot filled since (by hand): nothing is displaced, the attach is dropped
                local baseValid = act.isValid
                act.isValid = function(self)
                    local hb = self.hotbar
                    if hb and hb.attachedItems and hb.attachedItems[self.slotIndex] then return false end
                    return baseValid(self)
                end
                ISTimedActionQueue.add(act)
                n = n + 1
            end
        end
    end
    SA.lastAttached = n   -- (QA reads this: attaches queued by the last take)
    return n
end

-- ----------------------------------------------------------------------------
-- 2. A SPARE TO HAND WHEN THE WEAPON BREAKS
-- ----------------------------------------------------------------------------

-- the game's melee weapon categories (WeaponCategory, as its XP code asks them; Improvised says nothing of the kind)
local CATS = { "AXE", "BLUNT", "SPEAR", "LONG_BLADE", "SMALL_BLADE", "SMALL_BLUNT" }

-- A weapon's kind: "Firearm", the first melee category it has, or nil for a thing that is no weapon to fight with.
local function kindOf(w)
    if w:isRanged() then return "Firearm" end
    local script = w.getScriptItem and w:getScriptItem()
    if not (WeaponCategory and script and script.containsWeaponCategory) then return nil end
    for _, c in ipairs(CATS) do
        local cat = WeaponCategory[c]
        if cat and script:containsWeaponCategory(cat) then return c end
    end
    return nil
end
SA._kindOf = kindOf

-- How worn: condition for its maximum (0 is broken, 1 new).
local function wear(w)
    local max = w:getConditionMax()
    if not max or max <= 0 then return 1 end
    return w:getCondition() / max
end

--- The spare for a broken weapon, or nil. Attached slots first, then the main inventory (not bags). Same kind
--- first; else, for a melee weapon, any melee weapon; a firearm only for a firearm. The most worn wins; a tie keeps
--- the first found (the attached slot).
function SA.pickSpare(playerObj, broken, leftover)
    local want = kindOf(broken)
    if not want then return nil end
    local list, seen = {}, {}
    local hotbar = getPlayerHotbar and getPlayerHotbar(playerObj:getPlayerNum())
    if hotbar and hotbar.attachedItems then
        for _, i in ipairs(slotOrder({ availableSlot = hotbar.attachedItems })) do
            local it = hotbar.attachedItems[i]
            if it and not seen[it] then seen[it] = true; list[#list + 1] = it end
        end
    end
    local inv = playerObj:getInventory():getItems()
    for i = 0, inv:size() - 1 do
        local it = inv:get(i)
        if not seen[it] then seen[it] = true; list[#list + 1] = it end
    end
    local best, bestW, bestSame = nil, nil, false
    for _, it in ipairs(list) do
        if it ~= broken and it ~= leftover and instanceof(it, "HandWeapon") and not it:isBroken() and it:getCondition() > 0 then
            local k = kindOf(it)
            local ok = k ~= nil and ((want == "Firearm") == (k == "Firearm"))
            if ok then
                local same = k == want
                local w = wear(it)
                -- same kind beats any other; then the most worn; a tie keeps the earlier (attached first)
                if best == nil or (same and not bestSame) or (same == bestSame and w < bestW) then
                    best, bestW, bestSame = it, w, same
                end
            end
        end
    end
    return best
end

--- A broken weapon in (or just out of) his hands: the spare comes to hand. True when the equip was queued.
function SA.replaceBroken(playerObj, broken)
    if not (playerObj and broken and SA.on()) then return false end
    if not (instanceof(broken, "HandWeapon") and broken:isBroken()) then return false end
    if broken.getType and broken:getType() == "BareHands" then return false end
    if playerObj:getVehicle() then return false end
    if broken:isRanged() and playerObj:isAiming() then return false end
    -- the main hand already holds something else (he picked a new weapon himself); the off hand's torch can stay
    local prim = playerObj:getPrimaryHandItem()
    -- (QA lv_calls, Nov 24 2026) the game's OnBreak handlers put the broken weapon's leftover in the hand (a bat
    -- becomes BaseballBat_Broken, OnBreak.HandleHandler): that leftover is the break's own, not his new pick
    local lo = SA._leftover[playerObj]
    local left = lo and lo.from == broken and lo.left or nil
    SA._leftover[playerObj] = nil
    if prim and prim ~= broken and prim ~= left then return false end
    -- an equip already waiting (his own, or this one from the swing before): nothing more
    local q = ISTimedActionQueue.getTimedActionQueue(playerObj)
    for _, a in ipairs(q and q.queue or {}) do
        if a.Type == "ISEquipWeaponAction" then return false end
    end
    local spare = SA.pickSpare(playerObj, broken, left)   -- (never the leftover itself)
    if not spare then return false end
    ISInventoryPaneContextMenu.equipWeapon(spare, true, spare:isTwoHandWeapon(), playerObj:getPlayerNum())
    SA.lastSpare = spare   -- (QA reads this: the spare last sent to hand)
    return true
end

-- The leftover a break put in the hand, per player: { from = the broken weapon, left = what the hand holds now }.
-- (QA lv_calls, Nov 24 2026) The game's OnBreak.HandleHandler (shared/Items/OnBreak.lua) is the one handler that
-- puts a new item in the hand; it runs before the swing's OnPlayerAttackFinished.
SA._leftover = SA._leftover or {}
if OnBreak and OnBreak.HandleHandler and not OnBreak._zedSmartAttach then
    OnBreak._zedSmartAttach = true
    local origHandle = OnBreak.HandleHandler
    OnBreak.HandleHandler = function(item, player, newItemString, breakItem)
        local held = player and item and player.getPrimaryHandItem and player:getPrimaryHandItem() == item
        local r = origHandle(item, player, newItemString, breakItem)
        if held then
            local now = player:getPrimaryHandItem()
            if now and now ~= item then SA._leftover[player] = { from = item, left = now } end
        end
        return r
    end
end

-- multiplayer: swings that did not break the weapon yet, looked at again for a second (the break comes from the server)
SA._watch = SA._watch or {}
local WATCH_MS = 1000

--- The game's OnPlayerAttackFinished (each swing's end): a weapon broken by it is replaced.
function SA.onAttackFinished(playerObj, weapon)
    if not (playerObj and weapon) or not SA.on() then return end
    if playerObj.isLocalPlayer and not playerObj:isLocalPlayer() then return end
    if not instanceof(weapon, "HandWeapon") then return end
    if weapon:isBroken() then
        SA._watch[playerObj] = nil
        SA.replaceBroken(playerObj, weapon)
    elseif isClient() then
        SA._watch[playerObj] = { w = weapon, at = getTimestampMs() }
    end
end

--- Each tick while a swing is watched (multiplayer only): its weapon broken since is replaced, after a second let go.
function SA.tick()
    for p, e in pairs(SA._watch) do
        if e.w:isBroken() then
            SA._watch[p] = nil
            SA.replaceBroken(p, e.w)
        elseif getTimestampMs() - e.at > WATCH_MS then
            SA._watch[p] = nil
        end
    end
end

if not _G._zedSmartAttachHooked then
    _G._zedSmartAttachHooked = true
    Events.OnPlayerAttackFinished.Add(function(p, w) SA.onAttackFinished(p, w) end)
    Events.OnTick.Add(function()
        for _ in pairs(SA._watch) do SA.tick(); break end   -- (nothing watched: nothing done)
    end)
end
