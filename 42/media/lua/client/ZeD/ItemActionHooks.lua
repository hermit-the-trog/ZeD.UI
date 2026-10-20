-- ZeD-UI/42/media/lua/client/ZeD/ItemActionHooks.lua
-- ============================================================================
-- ITEM ACTION HOOKS (S122 — Phase B2)
-- Bridges PZ TimedAction lifecycle into ZeD.ItemActionManager so the new
-- ItemCard's Progress Band lights up during real cooking / reading /
-- repairing. Without this bridge the Manager always returns nil and the
-- Progress Band molecule short-circuits to height=0 (S120 + S121 baseline).
--
-- Approach: OnTick polling of the player's ISTimedActionQueue. Sniffing
-- subclass overrides of `start`/`perform`/`stop` is unreliable — many
-- PZ actions override the base methods without calling super, so a base-
-- class override misses them. The queue itself is the canonical source of
-- truth: queue[1] is the currently-executing action; when it changes, the
-- previous action is done.
--
-- Defensive everywhere: the polling can't crash the engine loop. Worst
-- case is an action goes unrecognized and the Band stays idle.
-- ============================================================================

local function _safeNotify(item, event, action)
    if not item or not (ZeD and ZeD.ItemActionManager and ZeD.ItemActionManager.notify) then return end
    pcall(ZeD.ItemActionManager.notify, item, event, action)
end

-- TimedAction subclasses store their target under different field names —
-- multi-probe to find it.
local function _actionItem(self)
    if not self or type(self) ~= "table" then return nil end
    return self.item or self.clothing or self.book or self.weapon or self.firearm
end

-- Classify by class name substring with multi-strategy fallback.
-- Strategy 1: self.Type (canonical, if present)
-- Strategy 2: metatable's __index.Type (when Type not on instance)
-- Strategy 3: field shape (self.book → reading; self.clothing+self.fabric → repairing; etc)
-- Strategy 4: item category (Literature item with active action → reading)
local function _classifyAction(self)
    if not self or type(self) ~= "table" then return nil, nil end

    -- Try Strategy 1+2: Type string
    local t = self.Type
    if (not t or t == "") then
        local mt = getmetatable(self)
        if mt and mt.__index and mt.__index.Type then t = mt.__index.Type end
    end
    if t and t ~= "" then
        local lower = string.lower(t)
        if lower:find("cook")    then return "cooking",   "COOKING"   end
        if lower:find("read")    then return "reading",   "READING"   end
        if lower:find("repair")
           or lower:find("fix")  then return "repairing", "REPAIRING" end
    end

    -- Strategy 3: field shape
    if self.book then return "reading", "READING" end
    if self.clothing and (self.fabric or self.thread or self.needle) then
        return "repairing", "REPAIRING"
    end

    -- Strategy 4: item is Literature → reading
    if self.item and instanceof and instanceof(self.item, "Literature") then
        return "reading", "READING"
    end

    return nil, nil
end

local function _actionPercent(self)
    if not self then return 0 end
    if self.getJobDelta then
        local ok, v = pcall(self.getJobDelta, self)
        if ok and type(v) == "number" then return math.max(0, math.min(1, v)) end
    end
    if type(self.maxTime) == "number" and self.maxTime > 0 and type(self.jobTime) == "number" then
        return math.max(0, math.min(1, self.jobTime / self.maxTime))
    end
    return 0
end

-- Per-player tracking — what action / item we last saw active so we can
-- emit "complete" when the queue advances or empties. Keyed by playerNum.
local _lastActive = {}  -- playerNum → {action, item}

local function _pollPlayer(p)
    if not p then return end
    local pn = p:getPlayerNum()
    -- S123: vanilla keys ISTimedActionQueue.queues by the CHARACTER OBJECT,
    -- not by player number (ISTimedActionQueue.lua:144). The old queues[pn]
    -- lookup was always nil, so the Band never lit from this path.
    local q  = ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue
               and ISTimedActionQueue.getTimedActionQueue(p)
    local last = _lastActive[pn]

    -- Resolve current head action
    local head = nil
    if q and q.queue and q.queue[1] then head = q.queue[1] end


    -- Reclassify head — ignore actions we don't surface
    local kind, label = _classifyAction(head)
    if not kind then head = nil end  -- treat as "no relevant action"

    if head then
        local item = _actionItem(head)
        if not item then return end

        if not last or last.action ~= head then
            -- Action transitioned — emit complete on previous, start on new
            if last then _safeNotify(last.item, "complete", nil) end
            _safeNotify(item, "start", {
                kind    = kind,
                label   = label,
                percent = _actionPercent(head),
                _action = head,
            })
            _lastActive[pn] = {action = head, item = item}
        else
            -- Same action — tick percent
            _safeNotify(item, "tick", {
                kind    = kind,
                label   = label,
                percent = _actionPercent(head),
                _action = head,
            })
        end
    else
        -- No relevant action active — clear any prior state
        if last then
            _safeNotify(last.item, "complete", nil)
            _lastActive[pn] = nil
        end
    end
end

local function _onTick()
    if not ISTimedActionQueue or not ISTimedActionQueue.queues then return end
    -- Poll all players (split-screen aware via getNumActivePlayers)
    local n = (getNumActivePlayers and getNumActivePlayers()) or 1
    for i = 0, n - 1 do
        local p = getSpecificPlayer(i)
        if p then _pollPlayer(p) end
    end
end

Events.OnTick.Add(_onTick)

Events.OnGameStart.Add(function()
    _lastActive = {}
end)

-- Fallback path: poll IsoPlayer state for reading specifically. Some read
-- mechanisms in PZ Build 42 may not go through ISTimedActionQueue (e.g.
-- the per-character reading-handler in IsoGameCharacter). Detect via
-- :isReading() and resolve the book via :getReadingItem() / :getReadBook().
local _readActiveItem = {}  -- pn → item currently being read
local _readScanTick = {}    -- pn → ticks since the inventory was last scanned for the book
local READ_RESCAN = 30      -- the book found is trusted this many ticks before looking again
local READ_PROBES = { "getReadingItem", "getReadBook", "getCurrentReadingItem",
                      "getLastReadBook", "getReadCharacter" }

local function _pollReadingFallback(p)
    if not p or not p.isReading then return end
    local pn = p:getPlayerNum()
    local ok, reading = pcall(p.isReading, p)
    if not ok then return end

    if reading then
        -- Multi-probe for the book the player is reading.
        -- 1. Try common method names on IsoPlayer / IsoGameCharacter.
        -- 2. Fallback: any Literature item in primary/secondary hand.
        --    (Reading actions equip the book to a hand for the duration.)
        local book = nil
        local probeName = nil
        for _, method in ipairs(READ_PROBES) do
            if not book and p[method] then
                local ok2, b = pcall(p[method], p)
                if ok2 and b then book = b; probeName = method end
            end
        end
        if not book and p.getPrimaryHandItem then
            local ok2, h = pcall(p.getPrimaryHandItem, p)
            if ok2 and h and instanceof and instanceof(h, "Literature") then
                book = h; probeName = "primaryHand"
            end
        end
        if not book and p.getSecondaryHandItem then
            local ok2, h = pcall(p.getSecondaryHandItem, p)
            if ok2 and h and instanceof and instanceof(h, "Literature") then
                book = h; probeName = "secondaryHand"
            end
        end
        -- Last-resort: scan inventory for a Literature item. PZ may not
        -- equip the book during reading. If multiple Lit items exist, prefer
        -- the one currently displayed in any open ItemCard (matches user
        -- intent — they opened the card for the book they're reading).
        -- The scan is the costly step, so once a book has been found it is
        -- kept for a while instead of being searched for again every tick
        -- (progress still updates every tick below).
        if not book and _readActiveItem[pn] then
            local t = (_readScanTick[pn] or 0) + 1
            if t < READ_RESCAN then
                _readScanTick[pn] = t
                book = _readActiveItem[pn]; probeName = "kept"
            else
                _readScanTick[pn] = 0
            end
        end
        if not book and p.getInventory then
            local ok2, inv = pcall(p.getInventory, p)
            if ok2 and inv and inv.getItems then
                local items = inv:getItems()
                local n = items:size()
                local litItems = {}
                for i = 0, n - 1 do
                    local it = items:get(i)
                    if it and instanceof and instanceof(it, "Literature") then
                        litItems[#litItems + 1] = it
                    end
                end
                if #litItems == 1 then
                    book = litItems[1]; probeName = "invScan(unique)"
                elseif #litItems > 1 then
                    -- Multiple — pick the carded one if any window has it as drawerItem
                    local carded = nil
                    -- S123: the window accessor is getWindow(); .instance never existed.
                    local cwin = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow
                                 and ZeD_CharacterWindow.getWindow()
                    if cwin and cwin._drawerItem then carded = cwin._drawerItem end
                    if carded then
                        for _, it in ipairs(litItems) do
                            if it == carded then book = it; probeName = "invScan(carded)"; break end
                        end
                    end
                    if not book then
                        -- Fallback: pick the one with the highest already-read page count
                        -- (the active read action increments this each tick).
                        local best, bestPages = nil, -1
                        for _, it in ipairs(litItems) do
                            local pages = (it.getAlreadyReadPages
                                and (function() local ok, v = pcall(it.getAlreadyReadPages, it); return ok and v or 0 end)())
                                or 0
                            if pages > bestPages then best, bestPages = it, pages end
                        end
                        -- S123: novels report -1 pages, so a tie leaves best nil; fall back to the first.
                        book = best or litItems[1]
                        probeName = "invScan(bestPages)"
                    end
                end
            end
        end
        if not book then return end

        -- Compute progress: getReadHours / getCharacterReadHours / item:getNumberOfPages + getAlreadyReadPages
        local percent = 0
        if book.getNumberOfPages and book.getAlreadyReadPages then
            local ok2, total = pcall(book.getNumberOfPages, book)
            local ok3, read  = pcall(book.getAlreadyReadPages, book)
            if ok2 and ok3 and total and total > 0 then
                percent = math.max(0, math.min(1, read / total))
            end
        end

        local prev = _readActiveItem[pn]
        if prev ~= book then
            if prev then _safeNotify(prev, "complete", nil) end
            _safeNotify(book, "start", {
                kind = "reading", label = "READING",
                percent = percent, _action = nil,
            })
            _readActiveItem[pn] = book
        else
            _safeNotify(book, "tick", {
                kind = "reading", label = "READING",
                percent = percent, _action = nil,
            })
        end
    else
        local prev = _readActiveItem[pn]
        if prev then
            _safeNotify(prev, "complete", nil)
            _readActiveItem[pn] = nil
        end
        _readScanTick[pn] = nil
    end
end

-- ---------------------------------------------------------------------------
-- COOKING POLL (S123, Q127/Q128). Cooking is not a TimedAction: a Food item
-- cooks while it sits in an ACTIVATED heat-source container (stove, fire).
-- Watch the item each window currently cards; when its container parent is
-- activated, drive the Band: "active" until minutesToCook, then "danger"
-- (burn countdown) until isBurnt, then complete.
-- ---------------------------------------------------------------------------
local _cookTracked = {}   -- item -> true while we are reporting it

local function _cardedItems()
    local out = {}
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if cw and cw._drawerItem then out[#out + 1] = cw._drawerItem end
    if ww and ww._drawerItem then out[#out + 1] = ww._drawerItem end
    return out
 end

local function _heatActive(item)
    local ok, cnt = pcall(function() return item:getContainer() end)
    if not ok or not cnt then return false end
    local ok2, parent = pcall(function() return cnt:getParent() end)
    if not ok2 or not parent or not parent.Activated then return false end
    local ok3, act = pcall(parent.Activated, parent)
    return ok3 and act == true
end

local function _pollCooking()
    local seen = {}
    for _, item in ipairs(_cardedItems()) do
        if item and not seen[item] and instanceof and instanceof(item, "Food") then
            seen[item] = true
            local okC, cookable = pcall(item.isCookable, item)
            if okC and cookable and _heatActive(item) then
                local burnt  = (function() local ok, v = pcall(item.isBurnt, item);  return ok and v end)()
                local cooked = (function() local ok, v = pcall(item.isCooked, item); return ok and v end)()
                local ct     = (function() local ok, v = pcall(item.getCookingTime, item);   return ok and v or 0 end)()
                local toCook = (function() local ok, v = pcall(item.getMinutesToCook, item); return ok and v or 0 end)()
                local toBurn = (function() local ok, v = pcall(item.getMinutesToBurn, item); return ok and v or 0 end)()
                if burnt then
                    if _cookTracked[item] then _safeNotify(item, "complete", nil); _cookTracked[item] = nil end
                else
                    local danger = cooked or (toCook > 0 and ct >= toCook)
                    local percent, timeStr, mode, label
                    if danger then
                        local span = math.max(1, toBurn - toCook)
                        percent = math.max(0, math.min(1, (ct - toCook) / span))
                        timeStr = string.format("%dm", math.max(0, math.ceil(toBurn - ct)))
                        mode, label = "danger", "BURNING"
                    else
                        percent = toCook > 0 and math.max(0, math.min(1, ct / toCook)) or 0
                        timeStr = string.format("%dm", math.max(0, math.ceil(toCook - ct)))
                        mode, label = "active", "COOKING"
                    end
                    local desc = { kind = "cooking", label = label, mode = mode, percent = percent, timeStr = timeStr, _action = nil }
                    if not _cookTracked[item] then
                        _safeNotify(item, "start", desc); _cookTracked[item] = mode
                    elseif _cookTracked[item] ~= mode then
                        _safeNotify(item, "danger", desc); _cookTracked[item] = mode
                    else
                        _safeNotify(item, "tick", desc)
                    end
                end
            elseif _cookTracked[item] then
                _safeNotify(item, "complete", nil); _cookTracked[item] = nil
            end
        end
    end
    -- Items no longer carded: close them out.
    for item, _ in pairs(_cookTracked) do
        if not seen[item] then _safeNotify(item, "complete", nil); _cookTracked[item] = nil end
    end
end

local _origOnTick = _onTick
_onTick = function()
    _origOnTick()
    pcall(_pollCooking)
    -- Also run the reading fallback for each active player
    if not getSpecificPlayer then return end
    local n = (getNumActivePlayers and getNumActivePlayers()) or 1
    for i = 0, n - 1 do
        local p = getSpecificPlayer(i)
        if p then _pollReadingFallback(p) end
    end
end
Events.OnTick.Remove(_origOnTick)
Events.OnTick.Add(_onTick)
