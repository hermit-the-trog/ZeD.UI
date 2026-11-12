-- ZeD-UI/42/media/lua/client/ZeD/InventoryPicked.lua
-- ============================================================================
-- THE PICKED LINE. Client; the help line's resting words for an inventory side
-- (the Character window's inventory and bags, the World window's containers).
-- The help line explains what the pointer rests on; on nothing with help, it
-- says this.
--
-- Like the Finder's "3 of 48 selected": while rows are picked (a click, Ctrl or
-- Shift, a box drawn round them, or the controller's marks) the line says
-- "3 of 48 picked | 4.2 kg", so a pile's weight shows before it is moved. With
-- nothing picked it says "48 items". The container's own weight is the
-- heading's job and the character's load the title bar's, so this line no
-- longer repeats either.
--
-- A picked stack row counts every thing in it, as a drag of that row moves the
-- whole stack (InventoryRenderer.dragItems): a closed stack, or any stack in the
-- grid. An open stack's rows each count their own thing. The weight is summed
-- as the rows sum a stack (getUnequippedWeight) and shown as the rows show it,
-- one decimal.
--
-- Several columns: every picked thing in every shown column, against what all
-- the shown columns hold.
--
-- The inventory draws every frame and a pick can be hundreds of rows, so the
-- picks are looked at every CHECK_MS, not per frame, and weighed only when they
-- changed. A pick that stays put is weighed again every REWEIGH_MS: a bottle
-- drunk from while picked shows its new weight.
-- ============================================================================

ZeD = ZeD or {}
ZeD.InventoryPicked = ZeD.InventoryPicked or {}
local P = ZeD.InventoryPicked

local CHECK_MS   = 100    -- how often the picks are looked at
local REWEIGH_MS = 1000   -- how often an unchanged pick is weighed again

P.CHECK_MS, P.REWEIGH_MS = CHECK_MS, REWEIGH_MS

local function nowMs() return getTimestampMs and getTimestampMs() or 0 end

-- is this container shown as a grid (its List | Grid toggle)? Asked once per list per look, never per row
local function isGrid(inv, playerObj)
    local IR = ZeD.InventoryRenderer
    if not (inv and IR and IR.containerKey and IR.isGridKey) then return false end
    local ok, g = pcall(function() return IR.isGridKey(IR.containerKey(inv, playerObj)) end)
    return ok and g == true
end

-- one list's picks into the set: sel the picked rows, stacks row -> its stack, open stack key -> true
local function addList(set, n, sel, stacks, open, inv, playerObj)
    local grid = nil
    for it in pairs(sel) do
        local stk = stacks and stacks[it]
        local rows = nil
        if stk and stk.count and stk.count > 1 and stk.items then
            if grid == nil then grid = isGrid(inv, playerObj) end
            if grid or not (open and open[stk.key]) then rows = stk.items end
        end
        if rows then
            for _, si in ipairs(rows) do
                if not set[si] then set[si] = true; n = n + 1 end
            end
        elseif not set[it] then
            set[it] = true; n = n + 1
        end
    end
    return n
end

--- Every picked thing of an inventory side, as a set (thing -> true), and how many.
--- holder: the list panel (its own picked table, stacks and open stacks); cols: the
--- column states shown, or nil for the one list. A table two places share counts once
--- (in columns the panel's own table is the last column's).
function P.gather(holder, cols, playerObj)
    local set, n, seen = {}, 0, {}
    local own = holder._selectedItems
    if own then
        seen[own] = true
        n = addList(set, n, own, holder._stacks, holder._expandedStacks, holder._inventory, playerObj)
    end
    if cols then
        for _, cs in ipairs(cols) do
            local sel = cs.selectedItems
            if sel and not seen[sel] then
                seen[sel] = true
                n = addList(set, n, sel, cs.stacks, cs.expandedStacks, cs.inventory, playerObj)
            end
        end
    end
    return set, n
end

--- What the picked things weigh together (kg, unrounded).
function P.weigh(set)
    local w = 0
    local ok = pcall(function()
        for it in pairs(set) do w = w + (it:getUnequippedWeight() or 0) end
    end)
    return ok and w or 0
end

-- the same things in both sets
local function sameSet(a, an, b, bn)
    if not b or an ~= bn then return false end
    for k in pairs(a) do if not b[k] then return false end end
    return true
end

-- how many things the shown columns hold, as their headings count them
local function colsTotal(cols, playerObj)
    local t = 0
    for _, cs in ipairs(cols) do
        if cs.inventory then t = t + (ZeD.ContainerGates.count(cs.inventory, playerObj) or 0) end
    end
    return t
end

--- The resting words. holder: the inventory side's list panel (the cache lives on it);
--- cols: the shown column states, or nil for the one list; total: how many things the list
--- holds (nil: the columns' sum); oneKey / manyKey: the window's own "%1 item" / "%1 items".
function P.line(holder, cols, total, oneKey, manyKey, playerObj)
    local c = holder._zedPicked
    if not c then c = { n = 0, w = 0 }; holder._zedPicked = c end
    local now = nowMs()
    -- (a clock that went back, a load: look again at once)
    if not c.at or now - c.at >= CHECK_MS or now < c.at then
        c.at = now
        local set, n = P.gather(holder, cols, playerObj)
        local reweigh = not c.wAt or now - c.wAt >= REWEIGH_MS or now < c.wAt
        if reweigh or not sameSet(set, n, c.set, c.n) then
            c.set, c.n = set, n
            c.w = n > 0 and P.weigh(set) or 0
            c.wAt = now
            c.text = nil
        end
        if cols and total == nil then c.colsTotal = colsTotal(cols, playerObj) end
    end
    if total == nil then total = c.colsTotal or 0 end
    if c.text and c.total == total and c.oneKey == oneKey then return c.text end
    local n = c.n
    if n > 0 then
        c.text = ZeD.tr(n == 1 and "UI_ZeD_Inv_PickedOne" or "UI_ZeD_Inv_PickedMany", n, total, string.format("%.1f", c.w))
    else
        c.text = ZeD.tr(total == 1 and oneKey or manyKey, total)
    end
    c.total, c.oneKey = total, oneKey
    return c.text
end

--- Forget the cache: the next line looks at the picks at once (a test, a window rebuilt).
function P.reset(holder)
    if holder then holder._zedPicked = nil end
end
