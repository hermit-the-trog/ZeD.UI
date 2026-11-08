-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MakeUp.lua
-- ============================================================================
-- MAKE-UP — a part of the Identity tab's Hair and beard section (vanilla
-- windows B9; the director, Nov 7 2026: "Makeup is supposed to go with the
-- hair"). The game's make-up window (ISMakeUpUI, from an inventory make-up
-- item's Make Up option) is replaced by a third part beside Hair and Beard
-- (ZeD_HairBeard.lua draws it with the same rows, figures, Now and After): the
-- spots the make-up carried can do (the game's MakeUpDefinitions: each spot by
-- its category, Full face, Eyes, Eyeshadow, Lips) and, under Remove, the
-- make-up worn. One press on the row's verb button does it:
--   * Apply runs the game's own timed action, ISApplyMakeUp (the make-up item
--     used once, the spot worn, the one it replaces taken off);
--   * Remove does what the game's window does (it has no action for it): the
--     worn make-up comes off and goes.
-- The game's own rule for both: a mirror, carried or within reach (or in a
-- vehicle, or the foundation), read from the game's own menu function
-- (ISInventoryPaneContextMenu.doMakeUpMenu on a stand-in menu), so its words
-- (Tooltip_NeedMirror) and its rules are the game's.
-- Overrides/MakeUp.lua sends the make-up item's Make Up option here.
-- ============================================================================

require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.MakeUp = ZeD.MakeUp or {}
local MU = ZeD.MakeUp

local CATS = { "FullFace", "Eyes", "EyesShadow", "Lips" }   -- the game's categories, in its window's order
MU.CATS = CATS

local function defs() return (MakeUpDefinitions and MakeUpDefinitions.makeup) or {} end

function MU.defFor(fullType)
    for _, d in ipairs(defs()) do if d.item == fullType then return d end end
    return nil
end

function MU.spotName(d) return getText("MakeUpType_" .. tostring(d and d.name)) end
function MU.catName(cat) return getText("MakeUpCategory_" .. tostring(cat)) end

-- the make-up items carried, bags included (one walk): { [makeUpType] = the first item of that kind }
local function walk(inv, visit, depth)
    local items = inv and inv:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then
            visit(it)
            if depth < 3 and instanceof(it, "InventoryContainer") then walk(it:getInventory(), visit, depth + 1) end
        end
    end
end
function MU.carried(p)
    local by, n = {}, 0
    if not p then return by, n end
    walk(p:getInventory(), function(it)
        local t = it.getMakeUpType and it:getMakeUpType()
        if t and t ~= "" and not by[t] and (not it.getCurrentUses or (it:getCurrentUses() or 1) > 0) then by[t] = it; n = n + 1 end
    end, 0)
    return by, n
end

-- the make-up worn: { item, def } in the order the character wears it
function MU.worn(p)
    local out = {}
    if not p then return out end
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:getItemByIndex(i)
        local d = it and MU.defFor(it:getFullType())
        if d then out[#out + 1] = { item = it, def = d } end
    end
    return out
end

-- the game's mirror rule, asked of its own menu function on a stand-in menu (one option: available or not, and why)
local function recorder()
    local rec = { options = {} }
    function rec:addOption(name, target, onSelect, p1)
        local o = { name = name, target = target, onSelect = onSelect, param1 = p1 }
        self.options[#self.options + 1] = o
        return o
    end
    return setmetatable(rec, { __index = function() return function() end end })
end
local STAND_IN = { getFullType = function() return "" end }
function MU.mirror(p, item)
    local fn = ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.doMakeUpMenu
    if not (p and fn) then return false, getText("Tooltip_NeedMirror") end
    local rec = recorder()
    local ok, err = pcall(fn, rec, item or STAND_IN, p)
    if not ok then
        if ZeD.logOnce then ZeD.logOnce("makeup mirror", err) end
        return false, getText("Tooltip_NeedMirror")
    end
    local o = rec.options[1]
    if not o then return false, getText("Tooltip_NeedMirror") end
    if o.notAvailable then
        local why = (o.toolTip and o.toolTip.description) or getText("Tooltip_NeedMirror")
        -- (the game's tooltip goes back to its pool: this is read every half second while the section shows)
        local M = ISInventoryPaneContextMenu
        local used, pool = M.tooltipsUsed, M.tooltipPool
        if o.toolTip and type(used) == "table" and type(pool) == "table" then
            for i = #used, 1, -1 do
                if used[i] == o.toolTip then table.remove(used, i); pool[#pool + 1] = o.toolTip; break end
            end
        end
        return false, why
    end
    return true, nil
end

-- does the section offer the make-up part at all: make-up carried or worn
function MU.relevant(p)
    local _, n = MU.carried(p)
    return n > 0 or #MU.worn(p) > 0
end

-- the preview items the figures wear (one per kind, made once)
local _preview = {}
function MU.previewItem(fullType)
    local it = _preview[fullType]
    if it == nil then
        local ok, made = pcall(instanceItem, fullType)
        it = (ok and made) or false
        _preview[fullType] = it
    end
    return it or nil
end

-- the rows for ZeD_HairBeard: the spots to put on (grouped by category, the game's order), then the worn to take off.
-- Each row: key, part "makeup", label, ok, reason, run, req "none", grp, verb, tool (the item's name), mk (what the
-- row's figure wears: { wear = fullType } or { off = fullType }), instant (Remove: no timed action)
function MU.rows(p, prefer)
    local rows = {}
    if not p then return rows end
    local carried, nCarried = MU.carried(p)
    local worn = MU.worn(p)
    if nCarried == 0 and #worn == 0 then return rows end
    local wornTypes = {}
    for _, w in ipairs(worn) do wornTypes[w.item:getFullType()] = true end
    local okM, why = MU.mirror(p, prefer)
    for _, cat in ipairs(CATS) do
        for _, d in ipairs(defs()) do
            if d.category == cat and not wornTypes[d.item] then
                local use = nil
                -- the make-up the player picked the option on first, then the first that can do this spot
                if prefer and d.makeuptypes and d.makeuptypes[prefer:getMakeUpType()] then use = prefer end
                if not use then
                    for t, it in pairs(carried) do if d.makeuptypes and d.makeuptypes[t] then use = it; break end end
                end
                if use then
                    local ft = d.item
                    rows[#rows + 1] = { key = "m:a:" .. ft, part = "makeup", style = ft, label = MU.spotName(d), ok = okM,
                        reason = (not okM) and why or nil, req = "none", grp = cat, verb = "Apply", kind = "makeup",
                        tool = use:getDisplayName(), toolItem = use, mk = { wear = ft },
                        run = function(pl) ISTimedActionQueue.add(ISApplyMakeUp:new(pl, use, ft)) end }
                end
            end
        end
    end
    for _, w in ipairs(worn) do
        local it, ft = w.item, w.item:getFullType()
        rows[#rows + 1] = { key = "m:r:" .. ft, part = "makeup", style = ft, label = MU.spotName(w.def), ok = okM,
            reason = (not okM) and why or nil, req = "none", grp = "Remove", verb = "Remove", kind = "makeup",
            mk = { off = ft }, instant = true,
            run = function(pl)
                -- (the game's window: off the character and out of the inventory, then the look updates)
                pl:removeWornItem(it)
                pl:getInventory():Remove(it)
                triggerEvent("OnClothingUpdated", pl)
            end }
    end
    return rows
end

-- the make-up item's Make Up option (Overrides/MakeUp.lua): the Character window on Identity, the section on its
-- make-up part with the rows that item can do first. False when ZeD's window cannot open (the caller opens the game's).
function MU.open(p, item)
    if not (p and ZeD_CharacterWindow and ZeD_CharacterWindow.openTab) then return false end
    local pn = p:getPlayerNum()
    if not ZeD_CharacterWindow.openTab(pn, "identity") then return false end
    local win = ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local HB = ZeD.HairBeard
    if not (win and HB and HB.showMakeUp) then return false end
    HB.showMakeUp(win, item)
    return true
end

return MU
