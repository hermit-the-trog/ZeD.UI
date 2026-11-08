-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/VIF_DualRender_B42.lua
-- ============================================================================
-- SUPPORT FOR BETTER FOLDERS (mod id VIF_DualRender_B42, Workshop 3834889317).
-- Client. The mod's named folders become group rows in ZeD's inventory list;
-- what follows about the mod was read from its own code.
--
-- What the mod does: folders the player names, in the game's inventory list of
-- the character's own inventory (not bags, not loot). A folder only points at
-- real things, kept in the character's modData ("VirtualInventoryFolders_v1"):
-- a thing is filed by itself (dropped on the folder) or by type ("Move all items
-- of this type to folder"). Its VIFState holds the folders and the filing; its
-- VIFFolderRows wraps ISInventoryPane (refreshContainer, the drawing, the
-- mouse) to draw each folder as a row with its things under it, its weight, and
-- [+] / [-]; a "+" button beside the list's header makes a folder; a folder's
-- right-click renames, deletes (the things stay) or folds it; an item's
-- right-click gives "Move all items of this type to folder" and "Remove from
-- folder" (its VIFContextMenus, on the game's OnFillInventoryObjectContextMenu).
--
-- ZeD's Character window replaces the game's inventory page, so the folder rows
-- and the "+" button never show with ZeD on (the item menu's two lines did, and
-- filed things for a list nobody saw). This file shows the folders in ZeD's own
-- list, through the list's general hook ZeD.ContainerGroups (ContainerGroups.lua):
--   * in the character's own inventory, a filed thing is listed under its
--     folder instead of its category: with the list sorted by Category (ZeD's
--     grouped view), each folder is a folding row like a category, before the
--     categories, in the mod's folder order, named as the player named it; in
--     the other sorts the list stays flat and the category column names the
--     folder. The grid shows the same groups. A folder with nothing filed in it
--     yet is a group row too, count 0, as an empty container: a folder just
--     made shows at once.
--   * the item menu gets "Virtual folders" (the mod's words): Create folder...
--     and, for a filed thing, Rename folder... and Delete folder (keep items).
--     The names are typed in ZeD's prompt (the game's text box, which ZeD
--     replaces), with ZeD's keyboard on a controller. The filing lines are the
--     mod's own, in the same menu.
-- Every change goes through the mod's own VIFState.mutate (it saves the modData),
-- which this file wraps only to tell ZeD's lists to rebuild. Equipped and worn
-- things are never filed (the mod's rule; ZeD lists them on the Equip tab).
-- Not carried over: the folder's weight on its row
-- (ZeD's group rows give the count), the mod's own fold state (ZeD keeps its own,
-- as for categories) and dropping things on a folder row (filing is done from
-- the item menu).
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "VIF_DualRender_B42"

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

require "ZeD/ContainerGroups"
require "ISUI/ISTextBox"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = { gen = 0, panes = {} }
ZeD.ModSupport.VIF_DualRender_B42 = S

local PREFIX = "vif:"   -- ZeD's group key: "vif:<player number>:<the mod's folder id>"

-- the mod's tables (global once its client files have loaded)
local function api()
    if type(VIFState) == "table" and type(VIFState.getController) == "function" then return VIFState end
    return nil
end

--- The mod reads a pane's player and inventory to find the character's folders
--- (VIFState.getController); ZeD hands it a small table with just those two.
function S.pane(playerObj)
    if not playerObj then return nil end
    local pn = 0
    pcall(function() pn = playerObj:getPlayerNum() end)
    local inv = playerObj:getInventory()
    local p = S.panes[pn]
    if not p or p.inventory ~= inv then
        p = { player = pn, inventory = inv }
        S.panes[pn] = p
    end
    return p
end

--- The character's folder state (the mod's), or nil.
function S.state(playerObj)
    local V = api()
    local pane = V and S.pane(playerObj)
    if not pane then return nil end
    local ok, c = pcall(V.getController, pane)
    return ok and c and c.state or nil
end

-- the key of the thing as the mod files it (its VIFFolderRows.itemKey)
local function itemKey(item)
    if type(VIFFolderRows) == "table" and type(VIFFolderRows.itemKey) == "function" then
        local ok, k = pcall(VIFFolderRows.itemKey, item)
        if ok then return k end
    end
    return nil
end

--- The folder id a thing is filed in, or nil.
function S.folderOf(playerObj, item)
    local V, st = api(), S.state(playerObj)
    if not (V and st and item) then return nil end
    local ft = nil
    pcall(function() ft = item:getFullType() end)
    local ok, id = pcall(V.classify, st, itemKey(item), ft)
    if ok and id and st.folders[id] then return id end
    return nil
end

local function splitKey(key)
    if type(key) ~= "string" or key:sub(1, #PREFIX) ~= PREFIX then return nil end
    local pn, id = key:match("^vif:(%d+):(.+)$")
    if not pn then return nil end
    return tonumber(pn), id
end

local function stateOfNum(pn)
    local p = getSpecificPlayer and getSpecificPlayer(pn)
    return p and S.state(p) or nil
end

-- ---------------------------------------------------------------------------
-- THE GROUPS IN ZeD'S LIST
-- ---------------------------------------------------------------------------
local G = {}

function G.group(item, inv, playerObj, isPlayerInv)
    if not (isPlayerInv and playerObj and inv) or inv ~= playerObj:getInventory() then return nil end
    local id = S.folderOf(playerObj, item)
    if not id then return nil end
    return PREFIX .. tostring(S.pane(playerObj).player) .. ":" .. id
end

function G.label(key)
    local pn, id = splitKey(key)
    if not pn then return nil end
    local st = stateOfNum(pn)
    local f = st and st.folders[id]
    return f and f.name or nil
end

function G.rank(key)
    local pn, id = splitKey(key)
    if not pn then return nil end
    local st = stateOfNum(pn)
    for i, fid in ipairs(st and st.order or {}) do
        if fid == id then return i end
    end
    return nil
end

--- Every folder of the character, in the mod's order: listed even with nothing filed.
function G.keys(inv, playerObj, isPlayerInv)
    if not (isPlayerInv and playerObj and inv) or inv ~= playerObj:getInventory() then return nil end
    local st = S.state(playerObj)
    if not st then return nil end
    local pre = PREFIX .. tostring(S.pane(playerObj).player) .. ":"
    local out = {}
    for _, fid in ipairs(st.order or {}) do
        if st.folders[fid] then out[#out + 1] = pre .. tostring(fid) end
    end
    return out
end

--- Every change goes through the mod's VIFState.mutate, which bumps S.gen (below).
function G.sig(inv, playerObj, isPlayerInv)
    if not isPlayerInv then return 0 end
    return S.gen
end

S.G = G
ZeD.ContainerGroups.add(MOD_ID, G)

-- The mod's one door for changes: wrapped once to tell ZeD's lists (S.gen).
local function wrapMutate()
    local V = api()
    if not V or V._zedWrapped then return end
    local orig = V.mutate
    if type(orig) ~= "function" then return end
    V._zedWrapped = true
    V.mutate = function(...)
        local a, b = orig(...)
        S.gen = S.gen + 1
        return a, b
    end
end
wrapMutate()
if Events and Events.OnGameStart then Events.OnGameStart.Add(wrapMutate) end

-- ---------------------------------------------------------------------------
-- THE ITEM MENU: make, rename and delete folders (the mod's "+" button and its
-- folder rows' menu, which live on the game's list)
-- ---------------------------------------------------------------------------

--- A change through the mod, then ZeD's lists rebuild.
function S.change(playerObj, fn, ...)
    local V = api()
    local pane = V and S.pane(playerObj)
    if not (pane and type(fn) == "function") then return nil end
    local ok, r = pcall(V.mutate, pane, fn, ...)
    if not ok then print("[ZeD] Better Folders: " .. tostring(r)); return nil end
    return r
end

-- the game's text box (ZeD's prompt stands in for it); onName(text) on OK
local function askName(playerNum, title, start, onName)
    local box = ISTextBox:new(0, 0, 350, 165, title, start or "", nil, function(_, button)
        if not button or button.internal ~= "OK" then return end
        local entry = button.parent and button.parent.entry
        local text = entry and entry:getText() or ""
        if text and text:match("%S") then onName(text) end
    end, playerNum)
    box:initialise()
    box:addToUIManager()
    return box
end
S.askName = askName

function S.create(playerObj)
    local pn = S.pane(playerObj).player
    return askName(pn, getText("UI_VIF_FolderName"), "", function(name)
        S.change(playerObj, VIFState.createFolder, name)
    end)
end

function S.rename(playerObj, id)
    local st = S.state(playerObj)
    local f = st and st.folders[id]
    if not f then return nil end
    local pn = S.pane(playerObj).player
    return askName(pn, getText("UI_VIF_RenameFolder"), f.name, function(name)
        S.change(playerObj, VIFState.renameFolder, id, name)
    end)
end

function S.delete(playerObj, id)
    return S.change(playerObj, VIFState.deleteFolder, id)
end

-- the first real thing among what the menu was opened for
local function firstItem(items)
    for _, e in ipairs(items or {}) do
        if type(e) == "table" and e.items then
            local it = e.items[2] or e.items[1]
            if it and it.getFullType then return it end
        elseif e ~= nil and (type(e) ~= "table" or e.getFullType) then
            return e   -- (an InventoryItem: Java userdata in the game)
        end
    end
    return nil
end

function S.onFill(playerNum, context, items)
    if not (api() and context) then return end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on("windows") then return end   -- safe mode: the game's own list has the "+"
    local playerObj = getSpecificPlayer(playerNum)
    local item = firstItem(items)
    if not (playerObj and item) then return end
    local inv = nil
    pcall(function() inv = item:getContainer() end)
    if inv ~= playerObj:getInventory() then return end   -- (the mod files the character's own inventory only)
    local parent = context:addOption(getText("UI_VIF_VirtualFolders"), nil, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(parent, sub)
    sub:addOption(getText("UI_VIF_CreateFolder"), playerObj, S.create)
    local id = S.folderOf(playerObj, item)
    if id then
        sub:addOption(getText("UI_VIF_Rename"), playerObj, S.rename, id)
        sub:addOption(getText("UI_VIF_DeleteFolder"), playerObj, S.delete, id)
    end
    -- the filing lines are the mod's own (its VIFContextMenus.onFill, through the game's hidden
    -- inventory page); when that page does not point at the character's inventory they would be
    -- missing, so the same two go here instead
    if not S.modMenuReady(playerNum) then S.fileOptions(playerObj, item, sub) end
end

-- Will the mod's own item menu answer for this player? (its pane must hold the character's inventory)
function S.modMenuReady(playerNum)
    local ok, ready = pcall(function()
        local page = getPlayerInventory(playerNum)
        local pane = page and page.inventoryPane
        return pane ~= nil and VIFState.getController(pane) ~= nil
    end)
    return ok and ready == true
end

-- "Remove from folder" and "Move all items of this type to folder", through the mod's VIFState
function S.fileOptions(playerObj, item, menu)
    local st = S.state(playerObj)
    if not st then return end
    local ft = item:getFullType()
    local key = itemKey(item)
    local own = key and st.assignments[key]
    if own or st.typeRules[ft] then
        menu:addOption(getText("UI_VIF_RemoveFromFolder"), playerObj, function(p)
            if own then
                S.change(p, VIFState.assignVerified, item, nil, VIFFolderRows.itemKey)
            else
                S.change(p, VIFState.setTypeRule, ft, nil)
            end
        end)
    end
    if #st.order == 0 then return end
    local opt = menu:addOption(getText("UI_VIF_MoveTypeToFolder"), nil, nil)
    local to = ISContextMenu:getNew(menu)
    menu:addSubMenu(opt, to)
    for _, fid in ipairs(st.order) do
        local f = st.folders[fid]
        if f then
            to:addOption(f.name, playerObj, function(p) S.change(p, VIFState.setTypeRule, ft, fid) end)
        end
    end
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(function(...) return S.onFill(...) end)
end
