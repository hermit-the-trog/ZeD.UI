-- ZeD-UI/42/media/lua/client/ZeD/ExtraContainers.lua
-- ============================================================================
-- EXTRA CONTAINERS FOR THE CONTAINER STRIPS (a general hook for other mods)
--
-- The Character window's strip lists your main inventory, the bags you wear or
-- hold and your key rings; the World window's lists the containers in reach.
-- A mod that adds more containers to the game's own container buttons (bags
-- carried inside bags, for one) gets the same in ZeD by registering a provider
-- through the window:
--     ZeD_CharacterWindow.addContainerProvider(id, fn)
--     ZeD_WorldWindow.addContainerProvider(id, fn)
-- Each time a window rebuilds its list (about twice a second) it calls every
-- provider of its side:
--     fn(playerObj, list)  ->  { { container = ItemContainer,          (required)
--                                  item       = InventoryItem,          (the bag; optional)
--                                  parentItem = InventoryItem,          (the bag it is in; optional)
--                                  name       = string,                 (optional, else the bag's name)
--                                  texture    = Texture }, ... }        (optional, else the bag's icon)
-- `list` is the window's own list as built so far (read it, never change it).
-- Every container returned gets a button and a column of its own, exactly like
-- a worn bag (Character window) or a container in reach (World window), so
-- open, close, columns and transfers are the window's own. A container that is
-- already listed is skipped. A new one is placed right after the listed
-- container it is carried in (followed up through bags inside bags), else at
-- the end; the World window's floor stays last. A provider that throws an
-- error is skipped for that rebuild (the window never breaks on another mod).
-- ============================================================================

ZeD = ZeD or {}
-- One registry per window side. `or` keeps the registries if this file is
-- loaded a second time (a debug reload), so providers already added stay.
local X = ZeD.ExtraContainers or { char = {}, world = {} }
ZeD.ExtraContainers = X

-- Adds (or replaces, by id) a provider for one side: "char" or "world".
function X.add(side, id, fn)
    local reg = X[side]
    if not reg or type(fn) ~= "function" then return end
    for _, p in ipairs(reg) do
        if p.id == id then p.fn = fn; return end   -- same id: the newer function wins
    end
    reg[#reg + 1] = { id = id, fn = fn }
end

-- Which LISTED container is `inv` carried in? Climbs bag -> the container the
-- bag sits in -> that container's bag ... until it meets one in `listed`.
-- Gives nil for a container not carried in anything listed. The climb stops
-- after 16 steps, so a strange loop can never hang the game.
local function anchorOf(inv, listed)
    local cur = inv
    for _ = 1, 16 do
        local bag = cur:getContainingItem()           -- the item this container belongs to
        local parent = bag and bag:getContainer()      -- the container that item sits in
        if not parent then return nil end
        if listed[parent] then return parent end
        cur = parent
    end
    return nil
end

-- The window's entry for one provided container, in the shape that side uses
-- (the same fields its own entries carry, so the strip and the columns treat
-- it like any other).
local function makeEntry(side, inv, x, id)
    local bag = x.item or inv:getContainingItem()
    local e = {
        inventory  = inv,
        name       = x.name or (bag and bag:getName()) or "?",
        texture    = x.texture or (bag and bag:getTex()) or nil,
        item       = bag,
        parentItem = x.parentItem,
        provider   = id,                  -- which provider added it (for QA and logs)
    }
    if side == "char" then
        e.isMain = false
    else
        e.isFloor = false
        e.sourceType = "provided"
    end
    return e
end

-- Asks every provider of `side` for its containers and returns the window's
-- list with them placed in. When nothing is added it returns `list` itself.
function X.merge(side, playerObj, list)
    local reg = X[side]
    if not reg or #reg == 0 then return list end
    -- the containers the window listed itself (Java objects work as table keys)
    local listed, seen = {}, {}
    for _, e in ipairs(list) do
        if e.inventory then listed[e.inventory] = true; seen[e.inventory] = true end
    end
    local after, loose, added = {}, {}, false
    for _, p in ipairs(reg) do
        -- pcall: an error in the provider (another mod's code) only skips it
        local ok, got = pcall(p.fn, playerObj, list)
        if ok and type(got) == "table" then
            for _, x in ipairs(got) do
                local inv = type(x) == "table" and x.container or nil
                if inv and not seen[inv] then
                    seen[inv] = true
                    local okE, e = pcall(makeEntry, side, inv, x, p.id)
                    if okE and e then
                        added = true
                        local okA, a = pcall(anchorOf, inv, listed)
                        if okA and a then
                            -- grouped under the listed container it is carried in, in
                            -- the provider's order (a bag before the bags inside it)
                            after[a] = after[a] or {}
                            table.insert(after[a], e)
                        else
                            loose[#loose + 1] = e
                        end
                    end
                end
            end
        end
    end
    if not added then return list end
    -- Rebuild: every listed entry, each followed by the containers carried in it.
    -- The floor (World window) keeps the last place: what would follow it, and
    -- anything with no listed container to follow, goes in before it.
    local out = {}
    for _, e in ipairs(list) do
        local group = e.inventory and after[e.inventory]
        if e.isFloor then
            for _, n in ipairs(group or {}) do out[#out + 1] = n end
            for _, n in ipairs(loose) do out[#out + 1] = n end
            loose = {}
            out[#out + 1] = e
        else
            out[#out + 1] = e
            for _, n in ipairs(group or {}) do out[#out + 1] = n end
        end
    end
    for _, n in ipairs(loose) do out[#out + 1] = n end
    return out
end
