-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/nm_nested_containers.lua
-- ============================================================================
-- SUPPORT FOR [B42] NESTED CONTAINERS (mod id nm_nested_containers, Workshop
-- 3410947298, by Nikku Miru).
--
-- The mod gives a bag carried inside another container a container button of
-- its own in the game's inventory and loot windows (its Nested.lua, on the
-- game's OnRefreshInventoryWindowContainers event, "buttonsAdded"): for every
-- container the window already lists it walks the items, and each item that
-- is a container gets a button, then the bags inside that one, down to the
-- depth set in its options. ZeD's Character and World windows replace those
-- game windows, so the buttons the mod adds never show under ZeD.
--
-- This file feeds the same bags to ZeD's strips through the windows' general
-- hook (ZeD_CharacterWindow.addContainerProvider and
-- ZeD_WorldWindow.addContainerProvider, ExtraContainers.lua). A nested bag gets
-- a button and a column like a worn bag (Character window) or a container in
-- reach (World window): open, close, columns and transfers are ZeD's own. The
-- choice of bags is the mod's rule, read from its own options:
--   * "Nesting" for the player inventory / the loot inventory (off: nothing);
--   * "Depth" (1-10, default 2): how many bags deep below a listed container;
--   * player "Filter": Everything / Only Pockets (no bags inside worn or held
--     bags, only those in the main inventory) / Only Equipped (only bags inside
--     worn or held bags);
--   * its blacklist: the floor, the proximity inventory, truck beds, trailers
--     and trunks (the game already gives their bags a button), and car seats;
--   * on the player, the first level skips worn or held bags and key rings
--     (the window lists them already).
-- Two differences from the mod's own code, both on purpose: the depth is
-- counted per branch (the mod's counter does not go back up after a deep
-- branch, so with a depth of 3 or more some later bags can go missing), and
-- a container ZeD shows as locked (World window) is not looked into, as the
-- game's loot window does not list it. The mod's small parent-bag badge on the
-- button and its "Only Vehicle" loot filter (which its code never reads) are
-- not carried over. ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "nm_nested_containers"

-- Is the mod switched on? getActivatedMods() is a Java list of mod ids; a
-- workshop id can carry a leading backslash, which is cut off before comparing.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/ExtraContainers"
require "ZeD/ZeD_CharacterWindow"   -- (it loads the World window too)

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.nm_nested_containers = S

-- ---------------------------------------------------------------------------
-- THE MOD'S OPTIONS, read live from the game's mod options (PZAPI.ModOptions,
-- the mod registers them as "nm_nested_containers"), so a change in the
-- options screen counts at once. The mod's own defaults stand in when a value
-- cannot be read.
-- ---------------------------------------------------------------------------
local DEFAULTS = {
    nestedDepth    = 2,      -- slider 1-10
    nesting_Player = true,   -- tick box
    playerFilter   = 1,      -- combo box: 1 Everything, 2 Only Pockets, 3 Only Equipped
    nesting_Loot   = true,   -- tick box
}

function S.option(id)
    -- pcall: the options table belongs to the other mod (and the game's API)
    local ok, v = pcall(function()
        local o = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
        local op = o and o:getOption(id)
        return op and op:getValue()
    end)
    if ok and v ~= nil then return v end
    return DEFAULTS[id]
end

-- the depth as a whole number from 1 to 10 (a slider can hand back 2.0)
local function maxDepth()
    local d = math.floor(tonumber(S.option("nestedDepth")) or 2)
    if d < 1 then d = 1 elseif d > 10 then d = 10 end
    return d
end

-- ---------------------------------------------------------------------------
-- THE MOD'S RULES
-- ---------------------------------------------------------------------------

-- the mod's blacklist: container types it never looks into (matched anywhere in
-- the type, as its string.contains does)
local BLACKLIST = { "floor", "proxInv", "TruckBed", "Trailer", "Trunk" }

local function blacklistedType(inv)
    local t = tostring(inv:getType() or "")
    for _, word in ipairs(BLACKLIST) do
        -- find with `true` = plain text, not a Lua pattern
        if string.find(t, word, 1, true) then return true end
    end
    return false
end

-- a key ring: the game's flag (isKeyRing, which the mod calls) or ZeD's own test
local function isKeyRing(item)
    local ok, yes = pcall(function()
        if item.isKeyRing and item:isKeyRing() then return true end
        return item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING)
    end)
    return ok and yes == true
end

-- Collects the bags inside `inv` (an ItemContainer), `level` deep below a
-- listed container, into `out`; then the bags inside each of those, while the
-- depth allows. `skipOnPlayer` is the player when the first level must skip
-- worn or held bags and key rings (the mod's rule for the player inventory).
local function collect(inv, level, depth, out, skipOnPlayer)
    if level > depth then return end
    local parentItem = inv:getContainingItem()   -- the bag `inv` belongs to (nil for the main inventory or furniture)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:IsInventoryContainer() then
            local skip = level == 1 and skipOnPlayer ~= nil
                and (skipOnPlayer:isEquipped(item) or isKeyRing(item))
            if not skip then
                out[#out + 1] = {
                    container  = item:getInventory(),
                    item       = item,
                    parentItem = parentItem,
                    name       = item:getName(),
                }
                -- the bags inside this bag, one level deeper (a bag before its own bags)
                collect(item:getInventory(), level + 1, depth, out, nil)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- THE PROVIDERS
-- ---------------------------------------------------------------------------

-- Character window: the bags inside the containers it lists (main inventory,
-- worn and held bags, key rings), by the mod's player rules.
function S.charProvider(playerObj, list)
    local out = {}
    if not S.option("nesting_Player") then return out end
    local depth = maxDepth()
    local filter = tonumber(S.option("playerFilter")) or 1
    local mainInv = playerObj:getInventory()
    for _, e in ipairs(list) do
        local inv = e.inventory
        if inv and not blacklistedType(inv) then
            local bag = inv:getContainingItem()
            local onBody = bag ~= nil and playerObj:isEquipped(bag)
            -- Only Pockets: not inside worn or held bags; Only Equipped: not the main inventory
            local filtered = (filter == 2 and onBody) or (filter == 3 and inv == mainInv)
            if not filtered then collect(inv, 1, depth, out, playerObj) end
        end
    end
    return out
end

-- a car seat (the mod skips those; vehicle parts are found from the container)
local function isSeat(inv)
    -- pcall: a container with no vehicle part (furniture, a corpse) answers nil
    local ok, yes = pcall(function()
        local part = inv:getVehiclePart()
        return part ~= nil and part:getCategory() == "seat"
    end)
    return ok and yes == true
end

-- World window: the bags inside the containers in reach, by the mod's loot
-- rules. The floor and anything ZeD shows locked are left alone.
function S.worldProvider(playerObj, list)
    local out = {}
    if not S.option("nesting_Loot") then return out end
    local depth = maxDepth()
    for _, e in ipairs(list) do
        local inv = e.inventory
        if inv and not e.isFloor and not e.locked and not blacklistedType(inv) and not isSeat(inv) then
            collect(inv, 1, depth, out, nil)
        end
    end
    return out
end

ZeD_CharacterWindow.addContainerProvider(MOD_ID, S.charProvider)
ZeD_WorldWindow.addContainerProvider(MOD_ID, S.worldProvider)
