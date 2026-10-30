-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ListsMenu.lua
-- ============================================================================
-- LOADOUTS AND OUTFITS BY NAME (handoff equip_doll_v4_loadouts, part B3; mockup
-- frames r2_09 and r2_10)
--
--   * The right-click menu: Save to outfit (worn and wearable things only) and
--     Save to loadout (anything you can carry). Each opens the saved lists of
--     that kind by name, a check on the ones the item is already in (picking a
--     checked one takes it out), a rule, then New outfit... / New loadout...,
--     which makes a list with the item on it. They are vanilla options with a
--     submenu, so both looks show them: the list cascades, the icon strip
--     drills into the same names (ContextMenuRegistry reads zedCheck / zedPx).
--   * The item card's mark strip, its fourth button (Lists): a pop-up in the
--     context list's look with the lists and checkboxes (it stays open while
--     you tick), New, and the outfits only for things you wear.
--   * The name prompt every new list and rename asks through (ZeD's prompt:
--     vanilla's ISTextBox, which Overrides/Prompts.lua builds as ZeD_Prompt).
-- The data and its rules are ZeD_Lists.lua.
-- ============================================================================

require "ISUI/ISTextBox"
require "ZeD/ZeD_Lists"
require "ZeD/ZeD_ContextList"
require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.ListsUI = ZeD.ListsUI or {}
local LU = ZeD.ListsUI
local L = ZeD.Lists

-- ---------------------------------------------------------------------------
-- THE NAME PROMPT
-- ---------------------------------------------------------------------------
local function onNamed(_, button, fn)
    if not (button and button.internal == "OK") then return end
    local entry = button.parent and button.parent.entry
    local text = entry and entry:getText() or ""
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end
    pcall(fn, text)
end

--- Ask for a name (the prompt's field filled with `default`); fn(name) on OK.
function LU.askName(pn, title, default, fn)
    pn = pn or 0
    local box = ISTextBox:new(0, 0, 280, 180, title, default or "", nil, onNamed, pn, fn)
    box:initialise()
    box:addToUIManager()
    if JoypadState and JoypadState.players and JoypadState.players[pn + 1] then
        pcall(function() box.prevFocus = getJoypadFocus(pn) end)
        setJoypadFocus(pn, box)
    end
    LU.lastPrompt = box
    return box
end

local function newTitle(kind)
    return ZeD.tr(kind == "outfit" and "UI_ZeD_Lists_NameOutfit" or "UI_ZeD_Lists_NameLoadout")
end

--- Ask a name, then make a list of that kind with the items on it (none: an empty list).
-- done(list) after.
function LU.newList(p, kind, items, done)
    if not p then return end
    LU.askName(p:getPlayerNum(), newTitle(kind), L.uniqueName(p, kind), function(name)
        local l = L.create(p, kind, L.uniqueName(p, kind, name))
        if l then
            for _, it in ipairs(items or {}) do LU.addItem(p, l, it) end
            for _, ln in ipairs(l.lines) do ln._adding = nil end
        end
        if done then done(l) end
    end)
end

-- ---------------------------------------------------------------------------
-- ITEMS ON A LIST (a stack counts once, its amount the stack's)
-- ---------------------------------------------------------------------------
function LU.addItem(p, list, item)
    if not (list and item) then return end
    if list.kind == "outfit" and not L.canOutfit(item) then return end
    local ln = L.lineOfItem(list, item)
    if ln then
        if ln.rule ~= "this" and ln.unit == "n" and ln._adding then ln.amount = (ln.amount or 1) + 1 end
        return
    end
    ln = L.addLine(p, list.id, L.lineFor(p, item, list.kind))
    if ln then ln._adding = true end
end

-- (the mark of a line being filled from one press is dropped after it: the save keeps plain values)
local function settle(list)
    for _, ln in ipairs(list and list.lines or {}) do ln._adding = nil end
end

--- Are all the items on the list?
function LU.allIn(list, items)
    if not (list and items and #items > 0) then return false end
    for _, it in ipairs(items) do
        if not L.lineOfItem(list, it) then return false end
    end
    return true
end

--- Put the items on the list, or take them off when they are all there already.
function LU.toggle(p, list, items)
    if not list then return end
    if LU.allIn(list, items) then
        for _, it in ipairs(items) do
            local ln = L.lineOfItem(list, it)
            if ln then L.removeLine(p, list.id, ln.id) end
        end
    else
        for _, it in ipairs(items) do LU.addItem(p, list, it) end
        settle(list)
    end
end

local function canKind(kind, items)
    for _, it in ipairs(items) do
        if kind == "outfit" and not L.canOutfit(it) then return false end
        if kind == "loadout" and not L.canLoadout(it) then return false end
    end
    return #items > 0
end
LU.canKind = canKind

-- ---------------------------------------------------------------------------
-- THE RIGHT-CLICK MENU
-- ---------------------------------------------------------------------------
local function addSaveTo(context, p, items, kind)
    local key = (kind == "outfit") and "UI_ZeD_Lists_SaveToOutfit" or "UI_ZeD_Lists_SaveToLoadout"
    local option = context:addOption(ZeD.tr(key))
    option.zedPx = L.icon(kind)
    option.zedCategory = "INFO"
    pcall(function() option.iconTexture = ZeD.PxIcon.tex(L.icon(kind), 16) end)
    local sub = context:getNew(context)
    context:addSubMenu(option, sub)
    for _, l in ipairs(L.all(p, kind)) do
        local on = LU.allIn(l, items)
        local o = sub:addOption(l.name, p, function() LU.toggle(p, l, items) end)
        o.zedCheck = on
        o.zedCategory = "lists"
        pcall(function() sub:setOptionChecked(o, on) end)
    end
    local nk = (kind == "outfit") and "UI_ZeD_Lists_NewOutfitDots" or "UI_ZeD_Lists_NewLoadoutDots"
    local n = sub:addOption(ZeD.tr(nk), p, function() LU.newList(p, kind, items) end)
    n.zedPx = "plus"
    n.zedCategory = "new"
end

local function onFillInventory(pn, context, rawItems)
    if ZeD.Safe and ZeD.Safe.on() then return end
    if not L.on() then return end   -- (Loadouts and outfits off: no Save to outfit / Save to loadout)
    local p = getSpecificPlayer(pn)
    if not (p and context and rawItems) then return end
    local ok, items = pcall(ISInventoryPane.getActualItems, rawItems)
    if not ok or not items or #items == 0 then return end
    if canKind("outfit", items) then addSaveTo(context, p, items, "outfit") end
    if canKind("loadout", items) then addSaveTo(context, p, items, "loadout") end
end
LU.onFillInventory = onFillInventory

if not _G._zedListsMenuHooked then
    _G._zedListsMenuHooked = true
    Events.OnFillInventoryObjectContextMenu.Add(function(...) return ZeD.ListsUI.onFillInventory(...) end)
end

-- ---------------------------------------------------------------------------
-- THE MARK STRIP'S POP-UP
-- ---------------------------------------------------------------------------
--- The pop-up's rows for an item (a tree for ZeD_ContextList).
function LU.popupTree(p, item)
    local items = { item }
    local rows = {}
    local function kindRows(kind, cat)
        rows[#rows + 1] = { heading = true, category = cat,
            name = ZeD.tr(kind == "outfit" and "UI_ZeD_Lists_FilterOutfits" or "UI_ZeD_Lists_FilterLoadouts") }
        for _, l in ipairs(L.all(p, kind)) do
            local list = l
            rows[#rows + 1] = {
                name = l.name, category = cat, keepOpen = true,
                check = function() return L.lineOfItem(list, item) ~= nil end,
                note = function()
                    local ln = L.lineOfItem(list, item)
                    return ln and L.placeText(ln.place) or nil
                end,
                onFire = function() LU.toggle(p, list, items) end,
            }
        end
        rows[#rows + 1] = { name = ZeD.tr(kind == "outfit" and "UI_ZeD_Lists_NewOutfitWith" or "UI_ZeD_Lists_NewLoadoutWith"),
            category = cat .. "new", pxIcon = "plus", iconTexture = ZeD.PxIcon.tex("plus", 16), iconTintable = true,
            onFire = function() LU.newList(p, kind, items) end }
    end
    if L.canLoadout(item) then kindRows("loadout", "lo") end
    if L.canOutfit(item) then kindRows("outfit", "of")
    else rows[#rows + 1] = { heading = true, category = "ofnote", name = ZeD.tr("UI_ZeD_Lists_OutfitsOnlyWorn") } end
    return rows
end

--- Open the pop-up under (ax, ay) (screen px) for the item.
function LU.openPopup(pn, item, ax, ay)
    local p = getSpecificPlayer(pn or 0)
    if not (p and item) or not L.on() then return nil end
    if LU.popup and LU.popup._ctx and LU.popup._ctx.open then LU.popup:close() end
    local m = ZeD_ContextList:new(pn or 0, "cursor", ax, ay, { item }, LU.popupTree(p, item), nil)
    m.headText = ZeD.tr("UI_ZeD_Lists_ItemInLists", item:getDisplayName())
    m.headPx = L.icon("loadout")
    m:initialise()
    m:open()
    LU.popup = m
    return m
end

--- The words beside the strip's Lists button: "in 1 loadout", "in 2 lists" (nil: none).
function LU.inText(p, item)
    local hits = L.listsWith(p, item)
    local n = #hits
    if n == 0 then return nil end
    local kinds = {}
    for _, h in ipairs(hits) do kinds[h.list.kind] = true end
    if kinds.loadout and kinds.outfit then return ZeD.tr("UI_ZeD_Lists_InLists", n) end
    if kinds.outfit then return ZeD.tr(n == 1 and "UI_ZeD_Lists_InOutfitOne" or "UI_ZeD_Lists_InOutfitMany", n) end
    return ZeD.tr(n == 1 and "UI_ZeD_Lists_InLoadoutOne" or "UI_ZeD_Lists_InLoadoutMany", n)
end
