-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/KADropnLoot.lua
-- ============================================================================
-- SUPPORT FOR EASY DROP'N'LOOT (mod id KADropnLoot, Workshop 2871469707).
--
-- The mod puts two buttons straight onto the game's inventory page (its
-- EDNLUI.lua adds ISButtons to ISInventoryPage in createChildren), not into
-- the game's container-control handler lists, so ZeD's container buttons row
-- (ContainerControls.lua) never sees them:
--   * "Transfer Category" on your inventory: for every item category the loot
--     container already holds, move your items of that category into it.
--   * "Loot Category" on the loot container: for every item category your
--     inventory already holds, take the container's items of that category.
-- Favourite and worn or held items stay (the mod's own rule). The mod picks
-- the categories from what the OTHER container holds, not from a selected item.
-- (Its right-click rows "Drop all (Category)" / "Grab all (Category)" already
-- show in ZeD's item menu through the game's context menu event.)
--
-- This file registers a provider with the row (ZeD.ContainerControls.addProvider),
-- which puts both buttons in as words after the divider, with the container's own
-- buttons: "Transfer category" in the Character window's row, "Loot category" in
-- the World window's row. Their words, hover lines and "hide this button"
-- options are the mod's own (getText of its keys, EDNL_isDropKeyHidden /
-- EDNL_isLootKeyHidden). The move is the mod's own function,
-- EDNL_moveItemsByCategories, aimed at the containers ZeD's two windows show
-- (the mod's EDNL_dropItems / EDNL_lootItems read the game's parked pages,
-- which are not the containers on show under ZeD). Where the floor is one of
-- the two, ZeD's own floor path moves the same items by the same rule.
-- ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "KADropnLoot"

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

require "ZeD/Tr"
require "ZeD/ContainerControls"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.KADropnLoot = S

-- A global function of the mod, or nil when it has not loaded (the mod's Lua
-- files can load after ours, so this is looked up at the moment of use).
local function modFn(name)
    local f = _G[name]
    return type(f) == "function" and f or nil
end

-- The mod's "hide this button" tick box. Its two functions answer true when the
-- player ticked it; no answer (function missing, or it errors) counts as not hidden.
local function hidden(fnName)
    local f = modFn(fnName)
    if not f then return false end
    local ok, v = pcall(f)
    return ok and v == true
end

-- The mod's item category (its getItemCategory): the display category, else the
-- plain one. Kept in step with the mod so the button greys out exactly when the
-- mod's move would find nothing.
local function categoryOf(item)
    local c = item:getDisplayCategory()
    if c == nil then c = item:getCategory() end
    return c
end

-- The floor is not an ordinary container: ZeD moves things to and from it
-- through its own path (ZeD.ContainerControls.moveItems).
local function isFloor(inv)
    return inv ~= nil and inv:getType() == "floor"
end

-- The items the mod would move: everything in src whose category dest also holds,
-- except favourites and anything worn or held (the mod's own rule). A Lua array.
function S.plan(playerObj, src, dest)
    local out = {}
    if not (playerObj and src and dest) or src == dest then return out end
    -- the categories dest holds, as a set (a table used as keys, so "is it in?" is one lookup)
    local cats = {}
    local di = dest:getItems()
    for i = 0, di:size() - 1 do
        local c = categoryOf(di:get(i))
        if c ~= nil then cats[c] = true end
    end
    local si = src:getItems()
    for i = 0, si:size() - 1 do
        local item = si:get(i)
        local c = categoryOf(item)
        if c ~= nil and cats[c] and not item:isFavorite() and not playerObj:isEquipped(item) then
            out[#out + 1] = item
        end
    end
    return out
end

-- Does the move: the mod's own function for two ordinary containers, ZeD's
-- floor path when the floor is one of them.
function S.move(content, src, dest, lootBox)
    local playerObj = content._playerObj
    if not (playerObj and src and dest) then return end
    local pn = playerObj:getPlayerNum()
    -- walk to the loot container first (the floor is under your feet), as ZeD's own buttons do
    local loot = lootBox
    if loot and not isFloor(loot) and not luautils.walkToContainer(loot, pn) then return end
    local move = modFn("EDNL_moveItemsByCategories")
    if move and not isFloor(src) and not isFloor(dest) then
        -- the mod reads the categories from the items it is handed: dest's own item list
        local ok, err = pcall(move, dest:getItems(), pn, src, dest)
        if not ok then print("[ZeD] KADropnLoot: the mod's move failed: " .. tostring(err)) end
    else
        ZeD.ContainerControls.moveItems(playerObj, S.plan(playerObj, src, dest), dest)
    end
end

-- The mod's Title Case words in ZeD's sentence case ("Transfer Category" -> "Transfer
-- category"): ZeD.btnCase turns only ALL-CAPS labels, so a mod's Title Case needs this;
-- a word in capitals or with a digit (an abbreviation) is left as written.
local function sentence(s)
    s = tostring(s or "")
    local first = true
    return (s:gsub("%S+", function(w)
        if first then first = false; return w end
        if w:find("%d") or not w:find("%l") then return w end
        return w:lower()
    end))
end

-- One button for the row. labelKey: the mod's text key for its label; tipKey: the key
-- for its hover line; inv/other: the container it moves from / to; lootBox: the
-- one of the two that is the loot container (the player walks to it).
local function makeSpec(content, id, labelKey, tipKey, inv, other, lootBox)
    local playerObj = content._playerObj
    return {
        id = id,
        label = sentence(getText(labelKey)),   -- the mod's own words, in ZeD's sentence case
        help = getText(tipKey),           -- the mod's own tooltip, shown in the window's footer on hover
        -- live only with something to move (the mod's button is always live; this one
        -- greys out when its move would find nothing, like ZeD's own Same type)
        enabled = other ~= nil and #S.plan(playerObj, inv, other) > 0,
        run = function(ct)
            -- the row was built for this container; if the window moved on, wait for the next rebuild
            if ct._inventory ~= inv then return end
            S.move(ct, inv, other, lootBox)
        end,
    }
end

ZeD.ContainerControls.addProvider(MOD_ID, function(side, content, inv, other)
    -- nothing to offer if the mod's own function did not load
    if not (modFn("EDNL_moveItemsByCategories") and content and content._playerObj and inv) then return nil end
    if side == "char" then
        -- your side: your container's items go to the container on show in the World window
        if hidden("EDNL_isDropKeyHidden") then return nil end
        return { makeSpec(content, "dnl:transfer", "UI_drop_items_button", "UI_drop_items_button_tooltip", inv, other, other) }
    end
    -- the World window: the container on show gives to your container
    if hidden("EDNL_isLootKeyHidden") then return nil end
    return { makeSpec(content, "dnl:loot", "UI_loot_items_button", "UI_loot_items_button_tooltip", inv, other, inv) }
end)
