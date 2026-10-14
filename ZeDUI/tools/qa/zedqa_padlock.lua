-- ZeDUI/tools/qa/zedqa_padlock.lua  (S125)
-- Padlock card setup for the QA save. Copy to Zomboid/Lua/zedqa.lua and bump
-- zedqa.go; grep console.txt for "ZEDQA pl". Builds beside the character
-- (build cheat, Q155): a wooden crate (free, for Use Combination Padlock), a
-- small metal locker with things inside locked with the code 319, and a
-- second wooden crate on a key padlock whose key is not carried; gives two
-- Combination Padlocks and a Padlock with two keys. Prints the objects found.

local p = getPlayer()
local function say(s) print("ZEDQA pl " .. tostring(s)) end
p:setGodMod(true)

local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end

local function build(full, ox, oy)
    local info = findInfo(full)
    if not info then say("no info " .. full); return nil end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    p:setBuildCheat(true)
    local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
    b.buildCheat = true
    b.player = p:getPlayerNum()
    local sq = getCell():getGridSquare(px + ox, py + oy, 0)
    local ok, valid = pcall(function() b.sq = sq; return b:isValid(sq) end)
    if ok and valid then pcall(function() b:create(px + ox, py + oy, 0, false, nil) end) end
    p:setBuildCheat(false)
    say("build " .. full .. " at " .. (px + ox) .. "," .. (py + oy) .. " valid=" .. tostring(ok and valid))
    return sq
end

local function thumpOn(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoThumpable") and o:canBeLockByPadlock() then return o end
    end
    return nil
end

local n = 0
local sqs = {}
local function tick()
    n = n + 1
    if n == 1 then
        sqs.crate = build("Base.Wood_Crate_Lvl1", 1, -1)
        sqs.locker = build("Base.Metal_LockerSmall_Lvl1", -1, -1)
        sqs.keyed = build("Base.Wood_Crate_Lvl1", 1, 1)
    elseif n == 20 then
        local crate, locker, keyed = thumpOn(sqs.crate), thumpOn(sqs.locker), thumpOn(sqs.keyed)
        say("crate=" .. tostring(crate and crate:getName()) .. " locker=" .. tostring(locker and locker:getName()) .. " keyed=" .. tostring(keyed and keyed:getName()))
        if locker then
            local c = locker:getContainer()
            if c and c:getItems():size() == 0 then
                for _, it in ipairs({ "Base.TinnedBeans", "Base.TinnedBeans", "Base.Bandage", "Base.Hammer", "Base.Rope" }) do c:AddItem(it) end
            end
            locker:setLockedByCode(319)
        end
        if keyed then
            keyed:setLockedByPadlock(true)
            keyed:setKeyId(424242)
        end
        local inv = p:getInventory()
        for _ = 1, 2 do inv:AddItem("Base.CombinationPadlock") end
        local pad = inv:AddItem("Base.Padlock")
        if pad then pcall(function() pad:setNumberOfKey(2); pad:setKeyId(515151) end) end
        say("locker code=" .. tostring(locker and locker:getLockedByCode()) .. " keyed=" .. tostring(keyed and keyed:isLockedByPadlock())
            .. " combos=" .. inv:getCountType("Base.CombinationPadlock"))
        LK_QA = { crate = crate, locker = locker, keyed = keyed }
    elseif n == 30 then
        say("setup done")
        Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
