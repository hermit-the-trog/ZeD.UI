-- ============================================================================
-- ItemMeter.lua: what an item's one bar shows, its condition or how full it is (punch list 152)
-- ============================================================================
-- The director, Nov 11 2026: "condition is not always condition. Sometimes it's how much is in something." The
-- inventory's COND / AMT column, the grid cells' strip and the loot card read one bar per item from here:
--   "fluid"  a liquid container (a bottle, a pot, a gas can): how full, the fill bar's ten cells in the liquid
--            blue (T.info); its condition, if it has one, on the item card (the director: "One bar: amount wins")
--   "uses"   something that runs down (a lighter, a battery, thread, glue, propane): what is left, ten cells in a light
--            neutral, the text's own tone (the director, Nov 11 2026, after QA saw the accent's teal sit close to the
--            liquid blue: "A light neutral"), never close to the liquid blue or any accent, and no status colour
--   "cond"   something that wears: a weapon (any tool, pot or bottle swung), clothing, or anything already below
--            its full condition (a vehicle part, say): the status bar's five cells in the status colours
--   "hidden" a liquid container whose level the game hides (it shows none either)
--   nil      nothing to show: something that neither wears nor holds anything, at its full condition (a can of
--            beans, a book, a key), so the bar no longer reads "full" on things that can't change
-- ============================================================================

ZeD = ZeD or {}
ZeD.ItemMeter = ZeD.ItemMeter or {}
local IM = ZeD.ItemMeter

local function safe(o, m, ...)
    if not o then return nil end
    local f = o[m]
    if type(f) ~= "function" then return nil end
    local ok, v = pcall(f, o, ...)
    if ok then return v end
    return nil
end
local function isA(o, cls) local ok, v = pcall(instanceof, o, cls); return ok and v end
local function clamp(v) return math.max(0, math.min(1, v or 0)) end

--- An item's liquid container: its own, or, lying on the floor, its world object's (the game keeps the liquid there:
--- QA's Mac run on test 8, Nov 11 2026, found the floor's bottles with no liquid on their cards)
function IM.fluidOf(item)
    local fc = safe(item, "getFluidContainer")
    if fc then return fc end
    local wi = safe(item, "getWorldItem")
    return wi and safe(wi, "getFluidContainer") or nil
end

--- kind, f (0..1): see above
function IM.of(item)
    if not item then return nil end
    local fc = IM.fluidOf(item)
    if fc then
        local cap = safe(fc, "getCapacity") or 0
        if cap > 0 then
            if safe(fc, "isHiddenAmount") then return "hidden", nil end
            return "fluid", clamp((safe(fc, "getAmount") or 0) / cap)
        end
    end
    if isA(item, "DrainableComboItem") then
        local u = safe(item, "getCurrentUsesFloat") or safe(item, "getUsedDelta")
        if type(u) == "number" then return "uses", clamp(u) end
    end
    local cm = safe(item, "getConditionMax")
    if cm and cm > 0 then
        local c = safe(item, "getCondition") or cm
        if isA(item, "HandWeapon") or isA(item, "Clothing") or c < cm then return "cond", clamp(c / cm) end
    end
    return nil
end

--- A stack's one bar (punch list 162, the director, Nov 11 2026): the lowest of its items of the head's kind, so a
--- stack of full and empty bottles never reads fuller than its emptiest. items: the stack's items (nil or one: the head's)
function IM.ofStack(head, items)
    local kind, f = IM.of(head)
    if not items or #items < 2 or kind == nil or kind == "hidden" then return kind, f end
    for i = 1, #items do
        local k2, f2 = IM.of(items[i])
        if k2 == kind and f2 and f2 < f then f = f2 end
    end
    return kind, f
end

--- The bar's colour and whether it is the status bar's graduated five (cond) or the fill bar's ten
function IM.style(kind)
    if kind == "cond" then return nil, true end
    if kind == "fluid" then return ZeD.T and ZeD.T.info, false end
    return ZeD.T and ZeD.T.text, false   -- (uses: the light neutral, the text's tone)
end

--- What the bar's help line calls it ("Condition 64%", "Remaining 50%")
function IM.label(kind)
    local s = ZeD.tr((kind == "cond") and "IGUI_invpanel_Condition" or "IGUI_invpanel_Remaining")
    return ((tostring(s or "")):gsub("%s*:%s*$", ""))
end

--- The sort key: the bar's share; no bar sorts below an empty one
function IM.sortKey(item)
    local kind, f = IM.of(item)
    if kind == nil or kind == "hidden" then return -1 end
    return f
end

return IM
