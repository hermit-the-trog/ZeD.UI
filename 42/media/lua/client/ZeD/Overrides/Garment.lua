-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Garment.lua
-- ============================================================================
-- CLOTHING'S INSPECT (tailoring) — director, Oct 15 2026: "There is no inspect
-- clothing item hook yet, it goes to vanilla ui. tailoring happens through the
-- inspect function."
--
-- Vanilla's Inspect on a garment (the context menu, after it brings the item
-- out of a bag: ISInventoryPaneContextMenu.onInspectClothing ->
-- onInspectClothingUI) opened ISGarmentUI: the body parts it covers, holes,
-- blood, patches, defence, and right-click tailoring. The ZeD surface for a
-- garment is its item card (ItemCard / ItemCardOrganism: the per-part rows,
-- blood, patch material, the defence facts, WASH / REPAIR / PAD), so Inspect
-- now opens that card in the Character window with its parts open. Each torn
-- or patched part's dock opens vanilla's own tailoring choices for that part
-- (ZeD.Garment.tailorMenu: which fabric to patch with, patch every hole,
-- remove the patch or all of them, with vanilla's skill and defence notes),
-- in the ZeD list. Vanilla's window still opens if the card cannot, and
-- always while safe mode is on (SafeMode.lua).
-- HOOK_MAP row 30.
-- ============================================================================

require "ZeD/SafeMode"
require "ISUI/ISInventoryPaneContextMenu"
require "ISUI/ISGarmentUI"

ZeD = ZeD or {}
ZeD.Garment = ZeD.Garment or {}
local G = ZeD.Garment

local function _safe(fn, default) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return default end

-- vanilla's tailoring menu for one part (ISGarmentUI:doContextMenu, its rules and
-- tooltips), built for a garment without its window: a stand-in carries what
-- the window would (the character, the garment, its parts)
function G.tailorMenu(player, clothing, part, x, y)
    local parts = {}
    local cp = _safe(function() return clothing:getCoveredParts() end, nil)
    if cp then for i = 0, cp:size() - 1 do parts[#parts + 1] = cp:get(i) end end
    local stand = setmetatable({ chr = player, clothing = clothing, parts = parts }, { __index = ISGarmentUI })
    local context = ISGarmentUI.doContextMenu(stand, part, x, y)
    local pn = player:getPlayerNum()
    if context and JoypadState.players[pn + 1] then
        context.mouseOver = 1
        setJoypadFocus(pn, context)
    end
    return context
end

-- the garment's card in the Character window, its parts open
local function openCard(player, clothing)
    if not (ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow) then return false end
    local pn = player:getPlayerNum()
    local win = ZeD_CharacterWindow.getWindow()
    if not (win and ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen()) then
        if JoypadState.players[pn + 1] and ZeD_CharacterWindow.ensureBothOpenForGamepad then
            ZeD_CharacterWindow.ensureBothOpenForGamepad(pn)
        else
            ZeD_CharacterWindow.toggle(pn)
        end
        win = ZeD_CharacterWindow.getWindow()
    end
    local cnt = win and win._mainContent
    if not (cnt and win._updateDrawer) then return false end
    local sel = cnt._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    sel[clothing] = true
    cnt._selectedItems = sel
    cnt._lastClickedItem = clothing
    win._updateDrawer(cnt)
    local card = win._itemCard
    if card then
        card._foldStates = card._foldStates or {}
        card._foldStates["clothing_zones"] = true   -- the parts, open
    end
    return win._drawerItem == clothing
end
G.openCard = openCard

local function apply()
    if not ISInventoryPaneContextMenu or ISInventoryPaneContextMenu._zedGarment then return end
    ISInventoryPaneContextMenu._zedGarment = true
    local vanilla = ISInventoryPaneContextMenu.onInspectClothingUI
    ISInventoryPaneContextMenu._zedGarmentVanilla = vanilla
    ISInventoryPaneContextMenu.onInspectClothingUI = function(player, clothing)
        if ZeD.Safe.on() then return vanilla(player, clothing) end   -- safe mode: ISGarmentUI
        local ok, done = pcall(openCard, player, clothing)
        if ok and done then return end
        if not ok then print("[ZeD] Garment: Inspect kept vanilla's window: " .. tostring(done)) end
        return vanilla(player, clothing)
    end
    print("[ZeD] Overrides/Garment: clothing's Inspect opens the ZeD item card")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
