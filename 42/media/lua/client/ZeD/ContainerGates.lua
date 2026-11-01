-- ZeD-UI/42/media/lua/client/ZeD/ContainerGates.lua
-- ============================================================================
-- CONTAINER GATES (a general hook for other mods)
--
-- A mod that hides a container's contents until something happens (a search,
-- a lock of its own) changes what the game's inventory and loot pages list,
-- usually by wrapping ISInventoryPane:refreshContainer. ZeD's windows build
-- their lists from the container itself, so such a rule needs telling to ZeD.
-- A mod's support file (ZeD/ModSupport/<mod id>.lua) registers a gate:
--     ZeD.ContainerGates.add(id, fn)
--   fn(inv, playerObj) -> nil (the container lists as usual) or a gate:
--   {
--     keep    = function(item) -> true when the item shows in the list
--               (nil: nothing shows)
--     sig     = a number or string that changes whenever keep would answer
--               differently (the list is rebuilt when it changes)
--     empty   = the list's empty line while nothing shows ("Not searched.")
--     status  = the words in place of the weight line ("Not searched")
--     noMoves = true: the band's own moves (Take all, Same type, To floor,
--               Transfer all...) are left out for this container
--     refuse  = true: nothing goes into this container (drops, moves)
--     specs   = function(side, content, inv) -> band buttons for this
--               container, as ContainerControls.addProvider's specs
--               ({ id, label, enabled, help, run, primary })
--     band    = { text = "Searching...", progress = 0..1 or nil }: the
--               band's left line (a status mark and words) and a moving bar
--   }
-- The fields are read every frame: a gate keeps one table per container and
-- updates it in place (no new tables per frame).
-- A mod that starts something when the player picks a container (as the game's
-- ISInventoryPage:selectContainer does) registers:
--     ZeD.ContainerGates.addChosen(id, fn)
--   fn(inv, playerObj, side) is called once when a ZeD window's list starts
--   showing a container it did not show the frame before, while that list was
--   already on screen (a pick in the strip, a column added, a pad press). A
--   window that opens, or a list that comes back after a tab covered it, does
--   not count. side is "char" or "world".
-- Every call is in pcall: a gate that throws counts as no gate, once logged.
-- With nothing registered every function returns at once.
-- ============================================================================

ZeD = ZeD or {}
local G = ZeD.ContainerGates or { gates = {}, chosen = {}, errors = {}, frame = 0 }
ZeD.ContainerGates = G

local function addTo(list, id, fn)
    if type(fn) ~= "function" then return end
    for _, g in ipairs(list) do
        if g.id == id then g.fn = fn; return end   -- same id: the newer function wins
    end
    list[#list + 1] = { id = id, fn = fn }
end

local function logOnce(id, err)
    if G.errors[id] == nil then
        G.errors[id] = tostring(err)
        print("[ZeD] ContainerGates: " .. tostring(id) .. " failed: " .. tostring(err))
    end
end

function G.add(id, fn) addTo(G.gates, id, fn) end

-- The gate for one container, or nil.
function G.get(inv, playerObj)
    local list = G.gates
    if #list == 0 or not inv then return nil end
    for _, g in ipairs(list) do
        local ok, got = pcall(g.fn, inv, playerObj)
        if ok then
            if got then return got end
        else
            logOnce(g.id, got)
        end
    end
    return nil
end

-- Does an item show in this container's list?
function G.keeps(gate, item)
    if not gate then return true end
    local k = gate.keep
    if not k then return false end
    local ok, yes = pcall(k, item)
    return ok and yes and true or false
end

-- How many things the list shows (the container's own count with no gate).
function G.count(inv, playerObj)
    local items = inv and inv:getItems()
    if not items then return 0 end
    local gate = G.get(inv, playerObj)
    if not gate then return items:size() end
    -- counted again only when the gate's signature or the container's size changes
    local size = items:size()
    if gate._cnt and gate._cntSig == gate.sig and gate._cntN == size then return gate._cnt end
    local n = 0
    for i = 0, size - 1 do
        local item = items:get(i)
        if item and not item:isHidden() and G.keeps(gate, item) then n = n + 1 end
    end
    gate._cnt, gate._cntSig, gate._cntN = n, gate.sig, size
    return n
end

-- The gate's words in place of the weight line, or nil.
function G.status(inv, playerObj)
    local gate = G.get(inv, playerObj)
    return gate and gate.status or nil
end

-- The gate's empty line, or nil.
function G.emptyText(inv, playerObj)
    local gate = G.get(inv, playerObj)
    return gate and gate.empty or nil
end

-- Does a gate refuse things put into this container?
function G.refuses(inv, playerObj)
    local gate = G.get(inv, playerObj)
    return gate ~= nil and gate.refuse == true
end

-- ----------------------------------------------------------------------------
-- A CONTAINER PICKED: what the lists show, frame by frame
-- ----------------------------------------------------------------------------
function G.addChosen(id, fn)
    addTo(G.chosen, id, fn)
    if not G._ticking and Events and Events.OnPreUIDraw then
        G._ticking = true
        Events.OnPreUIDraw.Add(function() G.frame = G.frame + 1 end)
    end
end

local function wipe(t) for k in pairs(t) do t[k] = nil end end

-- Called by the list renderer for each container it draws (InventoryRenderer).
function G.seen(panel, inv, playerObj)
    local list = G.chosen
    if #list == 0 or not (panel and inv) then return end
    local side = panel._ccSide
    if not side then return end   -- only the two windows' lists
    local F = G.frame
    local st = panel._cgSeen
    if not st then
        st = { cur = {}, prev = {}, f = -10, live = false }
        panel._cgSeen = st
    end
    if st.f ~= F then
        -- the first container this panel draws in a new frame
        st.live = (st.f == F - 1)    -- the list was on screen the frame before
        st.prev, st.cur = st.cur, st.prev
        wipe(st.cur)
        st.f = F
    end
    if st.cur[inv] then return end
    st.cur[inv] = true
    if not st.live or st.prev[inv] then return end
    for _, c in ipairs(list) do
        local ok, err = pcall(c.fn, inv, playerObj, side)
        if not ok then logOnce(c.id, err) end
    end
end
