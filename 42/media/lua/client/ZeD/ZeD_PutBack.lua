-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PutBack.lua
-- ============================================================================
-- PUTTING THINGS BACK AFTER AN ACTION (director, Oct 24 2026: "an option to
-- automatically putting things back in the container they were in after
-- using for a game action, like changing a tire will take the pump and jack
-- out of a trunk and put it back after"; QUICK_CHORDS_SPEC.md section 4)
--
-- ZeD setup, "Put things back after an action" (Settings.lua putBack; off for
-- a new player). When on: the game queues an action as a run in one go (move
-- the things it needs into your main inventory, maybe put a tool in your hand,
-- then the action itself). ZeD notes the run as it is queued
-- (ISTimedActionQueue.add). Once the action finishes (ISTimedActionQueue
-- :onCompleted, where every finished action passes), what it moved in goes
-- back where it came from: a bag you carry, a container in reach (a trunk, a
-- shelf, a crate), the floor where you stand. A thing the action used up and
-- replaced (an opened can, an empty bottle) goes back in its place. Your
-- hands go back as they were, when the run changed them. Everything goes by
-- the game's own move and equip actions, so it takes the same game time as by
-- hand, and the game's own checks decide (out of reach, no room: it stays on
-- you).
-- Not after an interruption: a run whose queue is cleared (stop, cancel, a
-- zombie) is forgotten. Where the game puts things back itself (crafting and
-- a few context menu actions since Build 42.8: their moves back are queued
-- in the same run), ZeD leaves those things to the game.
-- ============================================================================

require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.PutBack = ZeD.PutBack or {}
local PB = ZeD.PutBack

local function on()
    if ZeD.Safe.on() then return false end
    local S = ZeD.Settings
    return S and S.putBackOn and S.putBackOn() or false
end
PB.on = on

-- actions that are part of the way to an action, never the action itself
local LEAD = { ISInventoryTransferAction = true, ISEquipWeaponAction = true, ISUnequipAction = true, ISWalkToTimedAction = true,
               ISPathFindAction = true, ISWaitWhileGettingUp = true, ISGetUpAction = true, ISOpenCloseDoor = true, ISGrabCorpseItem = true }
local EQUIP = { ISEquipWeaponAction = true, ISUnequipAction = true }

local tick = 0
Events.OnTick.Add(function() tick = tick + 1 end)

local runs = {}       -- character -> the run being queued this tick
local byMain = {}     -- main action -> its run
PB.queuing = false    -- (ZeD's own moves back are never noted as a run)
-- (QA: zedqa_put_back.lua sets PB.debug for a line per step)
local function trace(s) if PB.debug then print("[ZeD] PutBack: " .. s) end end

local function itemsOf(inv)
    local set = {}
    local items = inv and inv:getItems()
    if items then for i = 0, items:size() - 1 do set[items:get(i)] = true end end
    return set
end

-- an action queued: part of this tick's run for its character
function PB.noted(action)
    if PB.queuing or not on() or type(action) ~= "table" then return end
    local chr = action.character
    if not (chr and instanceof(chr, "IsoPlayer") and chr:isLocalPlayer()) then return end
    local run = runs[chr]
    if not run or run.tick ~= tick then
        run = { chr = chr, tick = tick, moved = {}, order = {}, gameBack = {}, equips = false,
                hands = { chr:getPrimaryHandItem(), chr:getSecondaryHandItem() }, before = itemsOf(chr:getInventory()) }
        runs[chr] = run
    end
    local t = action.Type
    local main = chr:getInventory()
    trace("queued " .. tostring(t) .. " (tick " .. tick .. ")")
    if t == "ISInventoryTransferAction" then
        local item, src, dst = action.item, action.srcContainer, action.destContainer
        if not (item and src and dst) then return end
        if run.main and src == main and run.moved[item] then
            run.gameBack[item] = true   -- (the game puts it back itself)
        elseif not run.main and dst == main and src ~= main then
            if not run.moved[item] then run.order[#run.order + 1] = item end
            run.moved[item] = { src = src, floor = (src:getType() == "floor") }
            trace("  moved in: " .. tostring(item:getFullType()) .. " from " .. tostring(src:getType()))
        end
    elseif EQUIP[t] then
        if not run.main then run.equips = true end
    elseif not LEAD[t] then
        if run.main then byMain[run.main] = nil end
        run.main = action
        byMain[action] = run
    end
end

-- the run's action finished: its moves back, then the hands
local function finish(run)
    local chr = run.chr
    trace("finished " .. tostring(run.main and run.main.Type) .. ": " .. #run.order .. " moved in, equips " .. tostring(run.equips))
    if not (chr and #run.order > 0) and not run.equips then return end
    local main = chr:getInventory()
    local now = itemsOf(main)
    local backs = {}   -- { item, container }
    local gone = {}
    for _, item in ipairs(run.order) do
        local m = run.moved[item]
        if not run.gameBack[item] then
            if now[item] then backs[#backs + 1] = { item, m.src }
            elseif item:getContainer() == nil then gone[#gone + 1] = m end   -- (used up)
        end
    end
    -- one thing used up and something new in its place (an opened can, an empty bottle): that goes back there
    if #gone == 1 then
        local fresh = {}
        for item in pairs(now) do if not run.before[item] and not run.moved[item] then fresh[#fresh + 1] = item end end
        if #fresh >= 1 and #fresh <= 2 then for _, item in ipairs(fresh) do backs[#backs + 1] = { item, gone[1].src } end end
    end
    PB.queuing = true
    local ok, err = pcall(function()
        local held = { chr:getPrimaryHandItem(), chr:getSecondaryHandItem() }
        for _, b in ipairs(backs) do
            local item, src = b[1], b[2]
            -- (a tool the run put in a hand comes out of the hand first)
            if item == held[1] or item == held[2] then ISTimedActionQueue.add(ISUnequipAction:new(chr, item, 50)) end
            ISTimedActionQueue.add(ISInventoryTransferAction:new(chr, item, main, src))
        end
        -- the hands as they were, when the run changed them and the things are still on you
        if run.equips then
            local p0, s0 = run.hands[1], run.hands[2]
            local pn = chr:getPlayerNum()
            if p0 and held[1] ~= p0 and p0:getContainer() == main then
                ISInventoryPaneContextMenu.equipWeapon(p0, true, p0:isTwoHandWeapon() and s0 == p0, pn)
            end
            if s0 and s0 ~= p0 and held[2] ~= s0 and s0:getContainer() == main then
                ISInventoryPaneContextMenu.equipWeapon(s0, false, false, pn)
            end
        end
    end)
    PB.queuing = false
    if not ok then print("[ZeD] PutBack: " .. tostring(err)) end
    PB.last = { backs = #backs, equips = run.equips }   -- (QA)
    trace("  " .. #backs .. " back, " .. #gone .. " used up")
end

local function apply()
    if not ISTimedActionQueue or ISTimedActionQueue._zedPutBack then return end
    ISTimedActionQueue._zedPutBack = true
    local origAdd = ISTimedActionQueue.add
    ISTimedActionQueue.add = function(action, ...)
        local a, b = origAdd(action, ...)
        local ok, err = pcall(PB.noted, action)
        if not ok then print("[ZeD] PutBack: " .. tostring(err)) end
        return a, b
    end
    local origDone = ISTimedActionQueue.onCompleted
    function ISTimedActionQueue:onCompleted(action)
        local run = action and byMain[action]
        if run then byMain[action] = nil end
        trace("completed " .. tostring(action and action.Type) .. (run and " (a run's)" or ""))
        origDone(self, action)
        if run and run.main == action and on() then
            local ok, err = pcall(finish, run)
            if not ok then print("[ZeD] PutBack: " .. tostring(err)) end
        end
    end
    -- an interruption clears the queue: the runs waiting on it are forgotten
    local origReset = ISTimedActionQueue.resetQueue
    function ISTimedActionQueue:resetQueue()
        for a, run in pairs(byMain) do if run.chr == self.character then byMain[a] = nil end end
        return origReset(self)
    end
    print("[ZeD] PutBack: after an action, what it took out goes back (when Put things back is on)")
end
PB._apply = apply

Events.OnGameBoot.Add(apply)
apply()
