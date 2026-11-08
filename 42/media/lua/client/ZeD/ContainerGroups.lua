-- ZeD-UI/42/media/lua/client/ZeD/ContainerGroups.lua
-- ============================================================================
-- CONTAINER GROUPS (client; a general hook for other mods, used by Better
-- Folders through ModSupport/VIF_DualRender_B42.lua)
--
-- ZeD's item lists group a container's things by category (sort by Category:
-- a folding row per category; the grid the same). A mod that files things into
-- groups of its own (folders the player names) changes the game's inventory
-- list, usually by wrapping ISInventoryPane:refreshContainer, which ZeD's lists
-- never run. Such a rule needs telling to ZeD. A mod's support file registers:
--     ZeD.ContainerGroups.add(id, def)
--   def = {
--     group = function(item, inv, playerObj, isPlayerInv) -> a group key (a
--             string the provider owns; give it a prefix of its own) or nil
--             (the item keeps its category)
--     label = function(key) -> the group row's words, or nil (not this
--             provider's key)
--     rank  = function(key) -> a number (lower first), or nil. Ranked groups
--             come before the categories, in rank order, either sort way.
--     sig   = function(inv, playerObj, isPlayerInv) -> a number or string that
--             changes whenever group, label or rank would answer differently
--             (the list is rebuilt when it changes)
--     keys  = function(inv, playerObj, isPlayerInv) -> a list of group keys
--             listed even with nothing in them (a folder with nothing filed
--             yet is a group row, count 0, as an empty container), or nil.
--             Sort by Category only; sig covers it too.
--   }
-- The category column of a filed item shows its group's words. ZeD keeps its
-- own fold state per group key, as for categories.
-- Every call is in pcall: a provider that throws counts as no provider, once
-- logged. With nothing registered every function returns at once.
-- ============================================================================

ZeD = ZeD or {}
local G = ZeD.ContainerGroups or { list = {}, errors = {} }
ZeD.ContainerGroups = G

local function logOnce(id, err)
    if G.errors[id] == nil then
        G.errors[id] = tostring(err)
        print("[ZeD] ContainerGroups: " .. tostring(id) .. " failed: " .. tostring(err))
    end
end

--- Registers a provider under id (the header has def's contract).
function G.add(id, def)
    if type(def) ~= "table" then return end
    for i, p in ipairs(G.list) do
        if p.id == id then G.list[i] = { id = id, def = def }; return end   -- same id: the newer one wins
    end
    G.list[#G.list + 1] = { id = id, def = def }
end

function G.any() return #G.list > 0 end

-- one provider's answer: (true, value) or (false) when it threw
local function ask(p, field, a, b, c, d)
    local fn = p.def[field]
    if type(fn) ~= "function" then return true, nil end
    local ok, v = pcall(fn, a, b, c, d)
    if not ok then logOnce(p.id, v); return false end
    return true, v
end

--- The group an item is filed in, or nil (its category).
function G.groupOf(item, inv, playerObj, isPlayerInv)
    local list = G.list
    if #list == 0 then return nil end
    for _, p in ipairs(list) do
        local ok, key = ask(p, "group", item, inv, playerObj, isPlayerInv)
        if ok and key ~= nil and key ~= "" then return tostring(key) end
    end
    return nil
end

--- A group key's words, or nil (not a provider's key: the category's words).
function G.label(key)
    local list = G.list
    if #list == 0 or key == nil then return nil end
    for _, p in ipairs(list) do
        local ok, s = ask(p, "label", key)
        if ok and s ~= nil then return tostring(s) end
    end
    return nil
end

-- A group key's rank, or nil (a category).
function G.rank(key)
    local list = G.list
    if #list == 0 or key == nil then return nil end
    for _, p in ipairs(list) do
        local ok, r = ask(p, "rank", key)
        if ok and type(r) == "number" then return r end
    end
    return nil
end

--- The group keys listed even when empty (every provider's keys, in its order,
--- each once). An empty list with nothing registered.
local NONE = {}
function G.keys(inv, playerObj, isPlayerInv)
    local list = G.list
    if #list == 0 then return NONE end
    local out, seen = nil, nil
    for _, p in ipairs(list) do
        local ok, ks = ask(p, "keys", inv, playerObj, isPlayerInv)
        if ok and type(ks) == "table" then
            for _, k in ipairs(ks) do
                if k ~= nil and k ~= "" then
                    k = tostring(k)
                    out, seen = out or {}, seen or {}
                    if not seen[k] then seen[k] = true; out[#out + 1] = k end
                end
            end
        end
    end
    return out or NONE
end

--- What the list's cache compares: false with nothing registered, else every
--- provider's signature joined.
function G.sig(inv, playerObj, isPlayerInv)
    local list = G.list
    if #list == 0 then return false end
    local s = ""
    for _, p in ipairs(list) do
        local ok, v = ask(p, "sig", inv, playerObj, isPlayerInv)
        s = s .. tostring(ok and v or "x") .. "|"
    end
    return s
end

--- Sorts the group rows in place: ranked groups first, by rank (ties by key);
--- then the rest by key, ascending when asc, else descending.
function G.sortKeys(keys, asc)
    if #G.list == 0 then
        if asc then table.sort(keys) else table.sort(keys, function(a, b) return a > b end) end
        return
    end
    local rk = {}
    for _, k in ipairs(keys) do rk[k] = G.rank(k) or false end
    table.sort(keys, function(a, b)
        local ra, rb = rk[a], rk[b]
        if ra and rb then
            if ra ~= rb then return ra < rb end
            return a < b
        end
        if ra then return true end
        if rb then return false end
        if asc then return a < b end
        return a > b
    end)
end
