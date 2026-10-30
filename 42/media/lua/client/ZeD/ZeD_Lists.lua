-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Lists.lua
-- ============================================================================
-- LOADOUTS AND OUTFITS: THE LISTS (handoff equip_doll_v4_loadouts, Oct 29 2026,
-- part B1; the director: "Loadout lists should live in the journal tab ...
-- Outfits and loadouts: Separate, mix freely")
--
-- The data and its rules, no drawing. A loadout is what you carry (gear and
-- supplies), an outfit what you wear (everything worn that isn't a container).
-- Kept with the character in its mod data, so they save with it and every
-- player in multiplayer has their own:
--
--   player:getModData().ZeD_Lists = {
--     v = 1,                       -- the stored shape's version (L.migrate)
--     nextId = 4,                  -- the next list id
--     lists = {
--       { id = 3, kind = "loadout" | "outfit", name = "Supply run",
--         nextLine = 8, lines = { line, ... } },
--     },
--   }
--
-- Each line is a recipe, not a snapshot (plain values only, so the save keeps it):
--   { id = 7,
--     sec    = "gear" | "supply" | "worn",
--     place  = "hand:main" | "hand:off" | "belt:<slot type>" | "worn:<location>"
--              | "bag:<container full type>" | "inv"   (anywhere on you),
--     rule   = "any" | "this",
--     type   = "Base.Axe"            (the full type; "this" falls back to it),
--     itemId = 123456                (rule "this": the item's getID()),
--     tag    = "base:flashlight"     (optional: any of a kind, by item tag),
--     kind   = "water" | "food"      (optional: any water / any food),
--     name   = "Hand Axe"            (its name when saved, for when it's gone),
--     minCond = 0.5, minFill = 0.5   (optional, 0..1),
--     amount = 2, unit = "n" | "l" | "cal",
--     per    = "day" | "fixed"       (supplies only) }
--
-- The Journal's Loadouts page (ZeD_JournalLists.lua), the right-click menu
-- (Overrides/ItemMenu.lua) and the item card's mark strip edit them through
-- this module. The Equip tab's bar, restock and unpack (parts B4 to B7) read
-- them: L.all, L.get, L.resolve (a line on you, in its place) and L.ready.
-- ============================================================================

require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Lists = ZeD.Lists or {}
local L = ZeD.Lists

L.VERSION = 1
L.KEY = "ZeD_Lists"
L.KINDS = { "loadout", "outfit" }

-- The two lists' pixel icons (ZeD.PxIcon ids). Design's own hanger and list icons are
-- still to come: swap the ids here and every surface follows (the Journal page, the
-- right-click menu, the item card's mark strip).
L.ICON = { outfit = "hanger", loadout = "view_list" }

-- bumped on every change: surfaces that keep something per frame check it
L.gen = L.gen or 0

-- The Loadouts and outfits switch (Settings.lua "loadouts"; director, Oct 30 2026: off for a new player).
-- Every surface asks it as it draws: off, the fold, the to-do, the Journal page, the Lists mark, the
-- right-click menu, the Loadouts ring and Restock are hidden and inert. The lists themselves are never
-- touched: on again, they all come back.
function L.on()
    local S = ZeD.Settings
    return S and S.loadoutsOn and S.loadoutsOn() or false
end

local function call(o, m, ...)
    if not o then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
L.call = call

local function touch() L.gen = L.gen + 1 end

-- ---------------------------------------------------------------------------
-- THE STORE
-- ---------------------------------------------------------------------------
-- Older shapes move forward here, one version at a time (v1 is the first).
function L.migrate(s)
    if type(s.v) ~= "number" then s.v = 1 end
    if type(s.lists) ~= "table" then s.lists = {} end
    if type(s.nextId) ~= "number" then
        local m = 0
        for _, l in ipairs(s.lists) do if (l.id or 0) > m then m = l.id end end
        s.nextId = m + 1
    end
    for _, l in ipairs(s.lists) do
        if type(l.lines) ~= "table" then l.lines = {} end
        if type(l.nextLine) ~= "number" then
            local m = 0
            for _, ln in ipairs(l.lines) do if (ln.id or 0) > m then m = ln.id end end
            l.nextLine = m + 1
        end
    end
    s.v = L.VERSION
    return s
end

--- The character's lists table (made the first time it is asked for).
function L.store(p)
    if not p then return nil end
    local md = p:getModData()
    local s = md[L.KEY]
    if type(s) ~= "table" then
        s = { v = L.VERSION, nextId = 1, lists = {} }
        md[L.KEY] = s
    elseif s.v ~= L.VERSION or type(s.lists) ~= "table" then
        L.migrate(s)
    end
    return s
end

--- Every list, or those of one kind ("loadout" / "outfit"), in the order they were made.
function L.all(p, kind)
    local s = L.store(p)
    if not s then return {} end
    if not kind then return s.lists end
    local out = {}
    for _, l in ipairs(s.lists) do if l.kind == kind then out[#out + 1] = l end end
    return out
end

function L.get(p, id)
    local s = L.store(p)
    if not (s and id) then return nil end
    for _, l in ipairs(s.lists) do if l.id == id then return l end end
    return nil
end

local function tidyName(name)
    name = tostring(name or ""):gsub("[\r\n\t]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #name > 40 then name = name:sub(1, 40) end
    return name
end

--- A name no list of that kind has yet: "Loadout 1", "Loadout 2" ...
function L.uniqueName(p, kind, base)
    local taken = {}
    for _, l in ipairs(L.all(p, kind)) do taken[string.lower(l.name or "")] = true end
    base = tidyName(base or "")
    if base ~= "" and not taken[string.lower(base)] then return base end
    local stem = (base ~= "") and base or ZeD.tr(kind == "outfit" and "UI_ZeD_Lists_DefaultOutfit" or "UI_ZeD_Lists_DefaultLoadout")
    local n = 1
    while taken[string.lower(stem .. " " .. n)] do n = n + 1 end
    return stem .. " " .. n
end

function L.create(p, kind, name)
    local s = L.store(p)
    if not s then return nil end
    kind = (kind == "outfit") and "outfit" or "loadout"
    name = tidyName(name)
    if name == "" then name = L.uniqueName(p, kind) end
    local l = { id = s.nextId, kind = kind, name = name, lines = {}, nextLine = 1 }
    s.nextId = s.nextId + 1
    s.lists[#s.lists + 1] = l
    touch()
    return l
end

function L.rename(p, id, name)
    local l = L.get(p, id)
    name = tidyName(name)
    if not l or name == "" then return false end
    l.name = name
    touch()
    return true
end

function L.delete(p, id)
    local s = L.store(p)
    if not s then return false end
    for i, l in ipairs(s.lists) do
        if l.id == id then table.remove(s.lists, i); touch(); return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- LINES
-- ---------------------------------------------------------------------------
function L.line(list, lineId)
    if not list then return nil end
    for _, ln in ipairs(list.lines) do if ln.id == lineId then return ln end end
    return nil
end

--- Add a line (a table in the shape above) to list id; returns the stored line.
function L.addLine(p, listId, line)
    local l = L.get(p, listId)
    if not (l and line) then return nil end
    line.id = l.nextLine
    l.nextLine = l.nextLine + 1
    l.lines[#l.lines + 1] = line
    touch()
    return line
end

function L.removeLine(p, listId, lineId)
    local l = L.get(p, listId)
    if not l then return false end
    for i, ln in ipairs(l.lines) do
        if ln.id == lineId then table.remove(l.lines, i); touch(); return true end
    end
    return false
end

--- Change some of a line's fields: L.editLine(p, 3, 7, { rule = "this" })
function L.editLine(p, listId, lineId, fields)
    local ln = L.line(L.get(p, listId), lineId)
    if not (ln and fields) then return nil end
    for k, v in pairs(fields) do
        if k ~= "id" then ln[k] = v end
    end
    touch()
    return ln
end

-- the amount's step and floor for its unit
local STEP = { n = 1, l = 0.5, cal = 100 }
function L.step(line) return STEP[line and line.unit or "n"] or 1 end

function L.setAmount(p, listId, lineId, amount)
    local ln = L.line(L.get(p, listId), lineId)
    if not ln then return nil end
    local st = L.step(ln)
    amount = math.max(st, math.floor(((tonumber(amount) or st) / st) + 0.5) * st)
    if amount > 9999 then amount = 9999 end
    ln.amount = amount
    touch()
    return amount
end

--- Any / This one. "this" keeps the item number the line was saved with (an any line
-- made from an item keeps it too, so switching back and forth loses nothing).
function L.setRule(p, listId, lineId, rule)
    local ln = L.line(L.get(p, listId), lineId)
    if not ln then return nil end
    if rule == "this" and not ln.itemId then return ln.rule end   -- (a line by kind has no one item)
    ln.rule = (rule == "this") and "this" or "any"
    if ln.rule == "this" then ln.amount = 1 end
    touch()
    return ln.rule
end

--- A day / Fixed (supplies)
function L.setPer(p, listId, lineId, per)
    local ln = L.line(L.get(p, listId), lineId)
    if not ln then return nil end
    ln.per = (per == "day") and "day" or "fixed"
    touch()
    return ln.per
end

--- The list's lines by section, in the page's order: loadouts Gear then Supplies,
-- outfits Worn. Returns { { sec = "gear", lines = {...} }, ... } (empty sections kept).
function L.sections(list)
    local secs = (list and list.kind == "outfit") and { "worn" } or { "gear", "supply" }
    local out, by = {}, {}
    for _, s in ipairs(secs) do
        local e = { sec = s, lines = {} }
        out[#out + 1] = e
        by[s] = e
    end
    for _, ln in ipairs(list and list.lines or {}) do
        local e = by[ln.sec] or out[1]
        e.lines[#e.lines + 1] = ln
    end
    return out
end

-- ---------------------------------------------------------------------------
-- ITEMS: what kind of thing it is, where it is
-- ---------------------------------------------------------------------------
local function lower(s) return string.lower(tostring(s or "")) end

-- a body location as the doll keys it: lower case, no "base:" group, no underscores
function L.normLoc(loc)
    if loc == nil then return nil end
    local s = lower(loc)
    local c = s:find(":", 1, true)
    if c then s = s:sub(c + 1) end
    s = s:gsub("_", "")
    if s == "" or s == "nil" or s == "null" then return nil end
    return s
end

local function isContainer(item) return call(item, "IsInventoryContainer") or instanceof(item, "InventoryContainer") end

local function wearLoc(item)
    if call(item, "IsClothing") then
        local loc = L.normLoc(call(item, "getBodyLocation"))
        if loc then return loc end
    end
    return L.normLoc(call(item, "canBeEquipped"))
end

--- Can it go on an outfit: worn things that aren't containers (bags, fanny packs,
-- webbing and holsters belong to loadouts: they carry the gear).
function L.canOutfit(item)
    if not item or isContainer(item) then return false end
    return wearLoc(item) ~= nil
end

--- Can it go on a loadout: anything you can carry (not furniture you pick up).
function L.canLoadout(item)
    if not item then return false end
    if instanceof(item, "Moveable") then return false end
    return true
end

local function isKey(item)
    if instanceof(item, "Key") then return true end
    local t = call(item, "getFullType") or ""
    return t:find("KeyRing", 1, true) ~= nil
end

-- clean water in a fluid container, in litres (0 for none)
local function waterIn(item)
    local fc = call(item, "getFluidContainer")
    if not fc then return 0 end
    local amt = call(fc, "getAmount") or 0
    if amt <= 0 then return 0 end
    local fl = call(fc, "getPrimaryFluid")
    local ft = lower(fl and (call(fl, "getFluidTypeString") or tostring(fl)))
    if ft:find("water", 1, true) and not ft:find("taint", 1, true) then return amt end
    return 0
end
L.waterIn = waterIn

-- a light that is used up (candles, propane) and fire starters count as supplies;
-- torches and lanterns are gear
local function consumableLight(item, t)
    if call(item, "getDisplayCategory") == "FireSource" then return true end
    return t:find("Candle", 1, true) ~= nil or t:find("Propane_Refill", 1, true) ~= nil
end

--- What a carried thing is on a loadout: "supply" (food, water, medicine, ammunition,
-- batteries, light that is used up) or "gear"; and for water its kind.
function L.classify(item)
    local t = call(item, "getFullType") or ""
    if waterIn(item) > 0 then return "supply", "water" end
    if instanceof(item, "Clothing") then return "gear" end
    local cat = call(item, "getDisplayCategory") or ""
    if cat == "Food" or (instanceof(item, "Food") and not call(item, "getFluidContainer")) then return "supply" end
    if cat == "FirstAid" or cat == "Bandage" or cat == "Ammo" then return "supply" end
    if t == "Base.Battery" then return "supply" end
    if cat == "LightSource" or cat == "FireSource" then
        if consumableLight(item, t) then return "supply" end
    end
    return "gear"
end

-- the hotbar slot an item is attached to: its slot type, or nil
local function beltSlotOf(p, item)
    local hb = getPlayerHotbar and getPlayerHotbar(p:getPlayerNum())
    if not (hb and hb.attachedItems and hb.availableSlot) then return nil end
    for i, it in pairs(hb.attachedItems) do
        if it == item then
            local slot = hb.availableSlot[i]
            return slot and slot.slotType or nil
        end
    end
    return nil
end

-- the worn location of an item the character wears, or nil
local function wornLocOf(p, item)
    local worn = p:getWornItems()
    if not worn then return nil end
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i)
        if wi and wi:getItem() == item then return L.normLoc(wi:getLocation()) end
    end
    return nil
end

--- Where the item is on the character now, as a line's place (nil: not on them).
function L.placeOf(p, item)
    if not (p and item) then return nil end
    if p:getPrimaryHandItem() == item then return "hand:main" end
    if p:getSecondaryHandItem() == item then return "hand:off" end
    local slot = beltSlotOf(p, item)
    if slot then return "belt:" .. tostring(slot) end
    local loc = wornLocOf(p, item)
    if loc then return "worn:" .. loc end
    local c = call(item, "getContainer")
    local inv = p:getInventory()
    if c == inv then return "inv" end
    local holder = c and call(c, "getContainingItem")
    if holder and call(inv, "containsRecursive", holder) or (holder and p:isEquipped(holder)) then
        return "bag:" .. tostring(call(holder, "getFullType"))
    end
    if c and call(c, "isInCharacterInventory", p) then return "inv" end
    return nil
end

-- ---------------------------------------------------------------------------
-- MATCHING AN ITEM TO A LINE
-- ---------------------------------------------------------------------------
local _tagCache = {}
local function hasTag(item, tag)
    if not tag then return false end
    local t = _tagCache[tag]
    if t == nil then
        local ok, r = pcall(function() return ItemTag.get(ResourceLocation.of(tag)) end)
        t = (ok and r) or false
        _tagCache[tag] = t
    end
    if not t then return false end
    local ok, r = pcall(function() return item:hasTag(t) end)
    return ok and r == true
end

local function condOk(line, item)
    if not line.minCond then return true end
    local mx = call(item, "getConditionMax") or 0
    if mx <= 0 then return true end
    return (call(item, "getCondition") or 0) / mx >= line.minCond
end

local function fillOk(line, item)
    if not line.minFill then return true end
    local f = call(item, "getCurrentUsesFloat") or call(item, "getUsedDelta")
    if f == nil then
        local fc = call(item, "getFluidContainer")
        local cap = fc and call(fc, "getCapacity") or 0
        if cap > 0 then f = (call(fc, "getAmount") or 0) / cap end
    end
    return f == nil or f >= line.minFill
end

--- Does the item meet the line's kind (type, tag or kind) and its minimums?
-- byId: rule "this" asks for that exact item (the fallback to its type is the caller's).
function L.matches(line, item, byId)
    if not (line and item) then return false end
    if byId and line.rule == "this" and line.itemId then return item:getID() == line.itemId end
    local ok
    if line.kind == "water" then ok = waterIn(item) > 0
    elseif line.kind == "food" then ok = instanceof(item, "Food") and not call(item, "isRotten")
    elseif line.tag then ok = hasTag(item, line.tag) or (line.type ~= nil and item:getFullType() == line.type)
    else ok = line.type ~= nil and item:getFullType() == line.type end
    return ok and condOk(line, item) and fillOk(line, item)
end

-- the line in a list that is this item (rule "this" by its number, any by its type)
function L.lineOfItem(list, item)
    if not (list and item) then return nil end
    local id = item:getID()
    for _, ln in ipairs(list.lines) do
        if ln.rule == "this" and ln.itemId == id then return ln end
    end
    for _, ln in ipairs(list.lines) do
        if ln.rule ~= "this" and L.matches(ln, item, false) then return ln end
    end
    return nil
end

--- The lists the item is in: { { list = l, line = ln }, ... }, loadouts first.
-- (remembered per item and change: the item card and its mark strip ask each frame)
local _with = { gen = -1, p = nil, by = {} }
function L.listsWith(p, item)
    if not (p and item) then return {} end
    if _with.gen ~= L.gen or _with.p ~= p then _with.gen, _with.p, _with.by = L.gen, p, {} end
    local id = item:getID()
    local hit = _with.by[id]
    if hit then return hit end
    hit = {}
    for _, kind in ipairs(L.KINDS) do
        for _, l in ipairs(L.all(p, kind)) do
            local ln = L.lineOfItem(l, item)
            if ln then hit[#hit + 1] = { list = l, line = ln } end
        end
    end
    _with.by[id] = hit
    return hit
end

-- ---------------------------------------------------------------------------
-- A LINE FROM AN ITEM
-- ---------------------------------------------------------------------------
local function baseLine(item, sec, place, rule)
    local ln = {
        sec = sec, place = place or "inv", rule = rule or "any",
        type = item:getFullType(), itemId = item:getID(),
        name = call(item, "getDisplayName") or item:getFullType(),
        amount = 1, unit = "n",
    }
    if sec == "supply" then ln.per = "fixed"; ln.rule = "any" end
    return ln
end

--- The line the item makes on a list of that kind (as the right-click menu and the
-- mark strip add it). Outfits: its worn place, any of its type. Loadouts: in a hand
-- or on the belt this one, the rest any; supplies fixed, at what it holds.
function L.lineFor(p, item, kind)
    if not item then return nil end
    if kind == "outfit" then
        local loc = (p and wornLocOf(p, item)) or wearLoc(item)
        return baseLine(item, "worn", "worn:" .. tostring(loc or "worn"), "any")
    end
    local place = (p and L.placeOf(p, item)) or "inv"
    local sec, k = L.classify(item)
    if sec == "supply" then
        local ln = baseLine(item, "supply", "inv", "any")
        if k == "water" then
            ln.kind, ln.unit = "water", "l"
            ln.name = ZeD.tr("UI_ZeD_Lists_Water")
            ln.amount = math.max(0.5, math.floor(waterIn(item) * 2 + 0.5) / 2)
        end
        return ln
    end
    -- (picked from a container off the character, it goes on you: "inv")
    local rule = (place:sub(1, 5) == "hand:" or place:sub(1, 5) == "belt:") and "this" or "any"
    return baseLine(item, "gear", place, rule)
end

--- Put the item on list id (or take it off when it is already there). Returns true
-- when it is on the list afterwards.
function L.toggleItem(p, listId, item)
    local l = L.get(p, listId)
    if not (l and item) then return false end
    local ln = L.lineOfItem(l, item)
    if ln then L.removeLine(p, listId, ln.id); return false end
    if l.kind == "outfit" and not L.canOutfit(item) then return false end
    L.addLine(p, listId, L.lineFor(p, item, l.kind))
    return true
end

--- A new list of that kind with the item on it.
function L.createWith(p, kind, name, item)
    local l = L.create(p, kind, name)
    if l and item then L.addLine(p, l.id, L.lineFor(p, item, kind)) end
    return l
end

-- ---------------------------------------------------------------------------
-- SAVE WHAT I CARRY / WHAT I WEAR (handoff B2)
-- ---------------------------------------------------------------------------
-- every item inside inv (and the containers in it), with its place
local function walk(inv, place, fn, depth)
    if not inv or depth > 4 then return end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        fn(it, place)
        if isContainer(it) and not isKey(it) then
            walk(it:getInventory(), "bag:" .. tostring(it:getFullType()), fn, depth + 1)
        end
    end
end

-- the carried things grouped into lines (the scan behind both Save and Add what I carry)
local function carryLines(p)
    local lines, taken, byKey = {}, {}, {}
    local function add(ln) lines[#lines + 1] = ln; return ln end
    -- the hands, the belt slots and the worn containers: each its own line
    local main, off = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    if main then taken[main] = true; add(baseLine(main, "gear", "hand:main", "this")) end
    if off and off ~= main then taken[off] = true; add(baseLine(off, "gear", "hand:off", "this")) end
    local hb = getPlayerHotbar and getPlayerHotbar(p:getPlayerNum())
    if hb and hb.attachedItems and hb.availableSlot then
        for i, it in pairs(hb.attachedItems) do
            if it and not taken[it] then
                taken[it] = true
                local slot = hb.availableSlot[i]
                add(baseLine(it, "gear", "belt:" .. tostring(slot and slot.slotType or i), "this"))
            end
        end
    end
    local worn = p:getWornItems()
    for i = 0, (worn and worn:size() or 0) - 1 do
        local wi = worn:get(i)
        local it = wi and wi:getItem()
        if it and isContainer(it) and not taken[it] then
            taken[it] = true
            add(baseLine(it, "gear", "worn:" .. tostring(L.normLoc(wi:getLocation()) or "back"), "any"))
        elseif it then
            taken[it] = true   -- (clothing belongs to outfits)
        end
    end
    -- their contents and the inventory's, grouped by type
    local function one(it, place)
        if taken[it] or isKey(it) then return end
        if p:isEquipped(it) then return end
        taken[it] = true
        local sec, k = L.classify(it)
        local key
        if sec == "supply" then key = (k == "water") and "water" or ("s|" .. it:getFullType())
        else key = "g|" .. it:getFullType() end
        local ln = byKey[key]
        if k == "water" then
            local l = waterIn(it)
            if ln then ln.amount = ln.amount + l
            else
                ln = add(baseLine(it, "supply", "inv", "any"))
                ln.kind, ln.unit, ln.amount, ln.itemId = "water", "l", l, nil
                ln.name = ZeD.tr("UI_ZeD_Lists_Water")
                byKey[key] = ln
            end
        elseif ln then
            ln.amount = ln.amount + 1
        else
            ln = add(baseLine(it, sec, (sec == "supply") and "inv" or place, "any"))
            byKey[key] = ln
        end
    end
    -- the bags first (their contents take the bag's place), then the main inventory
    for i = 0, (worn and worn:size() or 0) - 1 do
        local it = worn:get(i):getItem()
        if it and isContainer(it) then walk(it:getInventory(), "bag:" .. tostring(it:getFullType()), one, 1) end
    end
    for _, h in ipairs({ main, off }) do
        if h and isContainer(h) then walk(h:getInventory(), "bag:" .. tostring(h:getFullType()), one, 1) end
    end
    walk(p:getInventory(), "inv", one, 1)
    for _, ln in ipairs(lines) do
        if ln.unit == "l" then ln.amount = math.max(0.5, math.floor(ln.amount * 2 + 0.5) / 2) end
    end
    return lines
end
L.scanCarry = carryLines

--- Every worn thing that isn't a container, as any of its type at its location.
function L.scanWear(p)
    local lines = {}
    local worn = p and p:getWornItems()
    for i = 0, (worn and worn:size() or 0) - 1 do
        local wi = worn:get(i)
        local it = wi and wi:getItem()
        if it and not isContainer(it) then
            lines[#lines + 1] = baseLine(it, "worn", "worn:" .. tostring(L.normLoc(wi:getLocation()) or "worn"), "any")
        end
    end
    return lines
end

-- the same line already on the list (same section, place, rule and thing)
local function sameLine(a, b)
    if a.sec ~= b.sec or a.rule ~= b.rule then return false end
    if a.rule == "this" then return a.itemId == b.itemId end
    if a.kind or b.kind then return a.kind == b.kind end
    return a.type == b.type and (a.sec == "supply" or a.place == b.place)
end

--- Add lines to list id, skipping the ones it already has. Returns how many were added.
function L.merge(p, listId, lines)
    local l = L.get(p, listId)
    if not l then return 0 end
    local n = 0
    for _, ln in ipairs(lines or {}) do
        local dup = false
        for _, have in ipairs(l.lines) do if sameLine(have, ln) then dup = true; break end end
        if not dup then L.addLine(p, listId, ln); n = n + 1 end
    end
    return n
end

--- Save what I carry as a new loadout / what I wear as a new outfit.
function L.saveCarry(p, name)
    local l = L.create(p, "loadout", name)
    if l then L.merge(p, l.id, carryLines(p)) end
    return l
end
function L.saveWear(p, name)
    local l = L.create(p, "outfit", name)
    if l then L.merge(p, l.id, L.scanWear(p)) end
    return l
end

--- Add what I carry (a loadout) or what I wear (an outfit) to list id.
function L.addCurrent(p, listId)
    local l = L.get(p, listId)
    if not l then return 0 end
    if l.kind == "outfit" then return L.merge(p, listId, L.scanWear(p)) end
    return L.merge(p, listId, carryLines(p))
end

-- ---------------------------------------------------------------------------
-- THE RESOLVER: is a line on the character, in its place (B4's "ready n of m")
-- ---------------------------------------------------------------------------
-- the amount one item gives a line
local function amountOf(line, item)
    if line.unit == "l" then return waterIn(item) end
    if line.unit == "cal" then return math.max(0, call(item, "getCalories") or 0) end
    return 1
end

-- the items a place holds on the character (nil place: anywhere on them)
local function itemsAt(p, place)
    local out = {}
    if place == "hand:main" then out[1] = p:getPrimaryHandItem()
    elseif place == "hand:off" then out[1] = p:getSecondaryHandItem()
    elseif place and place:sub(1, 5) == "belt:" then
        local want = place:sub(6)
        local hb = getPlayerHotbar and getPlayerHotbar(p:getPlayerNum())
        if hb and hb.attachedItems and hb.availableSlot then
            for i, it in pairs(hb.attachedItems) do
                local slot = hb.availableSlot[i]
                if it and slot and tostring(slot.slotType) == want then out[#out + 1] = it end
            end
        end
    elseif place and place:sub(1, 5) == "worn:" then
        local want = place:sub(6)
        local worn = p:getWornItems()
        for i = 0, (worn and worn:size() or 0) - 1 do
            local wi = worn:get(i)
            if wi and L.normLoc(wi:getLocation()) == want then out[#out + 1] = wi:getItem() end
        end
    elseif place and place:sub(1, 4) == "bag:" then
        -- (worn and held bags are in the main inventory too: their contents carry the bag's place)
        walk(p:getInventory(), "inv", function(it, pl) if pl == place then out[#out + 1] = it end end, 1)
    else
        walk(p:getInventory(), "inv", function(it) out[#out + 1] = it end, 1)
    end
    return out
end
L.itemsAt = itemsAt

--- How a line stands on the character.
-- @param days  the trip's days (per-day lines multiply by it; default 1)
-- @return { ok, need, have (in its place), haveOnYou (anywhere on you), inPlace,
--           items (the matching items in place), fallback (a "this one" whose item
--           isn't on you, matched by its type instead) }
function L.resolve(p, line, days)
    local need = (line.amount or 1) * ((line.per == "day") and math.max(1, days or 1) or 1)
    local r = { need = need, have = 0, haveOnYou = 0, items = {}, ok = false, inPlace = false, fallback = false }
    if not (p and line) then return r end
    local anywhere = (line.sec == "supply") or line.place == "inv" or not line.place
    local byId = (line.rule == "this" and line.itemId) and true or false
    if byId then
        local found = false
        for _, it in ipairs(itemsAt(p, nil)) do if it:getID() == line.itemId then found = true; break end end
        if not found then byId = false; r.fallback = true end
    end
    local seen = {}
    local function count(list, inPlace)
        for _, it in ipairs(list) do
            if it and not seen[it] and L.matches(line, it, byId) then
                seen[it] = true
                local a = amountOf(line, it)
                r.haveOnYou = r.haveOnYou + a
                if inPlace then r.have = r.have + a; r.items[#r.items + 1] = it end
            end
        end
    end
    count(itemsAt(p, (not anywhere) and line.place or nil), true)
    if not anywhere then count(itemsAt(p, nil), false) end
    r.inPlace = r.have > 0
    r.ok = r.have + 1e-6 >= need
    return r
end

--- A list's lines that are on the character in their place, and how many lines it has.
function L.ready(p, list, days)
    local n = 0
    for _, ln in ipairs(list and list.lines or {}) do
        if L.resolve(p, ln, days).ok then n = n + 1 end
    end
    return n, list and #list.lines or 0
end

-- ---------------------------------------------------------------------------
-- WORDS (the page, the menu and the card show these)
-- ---------------------------------------------------------------------------
local function slotWord(loc)
    local D = ZeD.EquipDoll
    for _, s in ipairs(D and D.SLOTS or {}) do
        if s.locs and s.locs[loc] then return ZeD.tr(s.key) end
    end
    return loc
end

--- Where a line goes, in words: "main hand", "Belt Left", "worn: Back", "in the Hiking Bag", "on you".
function L.placeText(place)
    place = place or "inv"
    if place == "hand:main" then return ZeD.tr("UI_ZeD_Lists_PlaceMain") end
    if place == "hand:off" then return ZeD.tr("UI_ZeD_Lists_PlaceOff") end
    if place:sub(1, 5) == "belt:" then
        local st = place:sub(6)
        return getTextOrNull("IGUI_HotbarAttachment_" .. st) or st
    end
    if place:sub(1, 5) == "worn:" then return ZeD.tr("UI_ZeD_Lists_PlaceWorn", slotWord(place:sub(6))) end
    if place:sub(1, 4) == "bag:" then
        local ft = place:sub(5)
        local nm = getItemNameFromFullType and getItemNameFromFullType(ft) or ft
        return ZeD.tr("UI_ZeD_Lists_PlaceBag", nm or ft)
    end
    return ZeD.tr("UI_ZeD_Lists_PlaceInv")
end

--- The amount in words: "4", "1.5 L", "2400 cal".
function L.amountText(line)
    local a = line and line.amount or 1
    if line and line.unit == "l" then return ZeD.tr("UI_ZeD_Lists_Litres", string.format("%.1f", a)) end
    if line and line.unit == "cal" then return ZeD.tr("UI_ZeD_Lists_Calories", tostring(math.floor(a))) end
    if a == math.floor(a) then return tostring(math.floor(a)) end
    return string.format("%.1f", a)
end

--- The rule in words, short: "this one" / "any" (with its minimums).
function L.ruleText(line)
    if not line then return "" end
    local s = ZeD.tr(line.rule == "this" and "UI_ZeD_Lists_RuleThis" or "UI_ZeD_Lists_RuleAny")
    if line.minCond then s = s .. ", " .. ZeD.tr("UI_ZeD_Lists_MinCond", math.floor(line.minCond * 100 + 0.5)) end
    if line.minFill then s = s .. ", " .. ZeD.tr("UI_ZeD_Lists_MinFill", math.floor(line.minFill * 100 + 0.5)) end
    return s
end

--- "loadout | 9 lines"
function L.countText(list)
    local n = list and #list.lines or 0
    local kind = ZeD.tr(list and list.kind == "outfit" and "UI_ZeD_Lists_KindOutfit" or "UI_ZeD_Lists_KindLoadout")
    return kind .. " | " .. ZeD.tr(n == 1 and "UI_ZeD_Lists_LineOne" or "UI_ZeD_Lists_LineMany", n)
end

--- The lists an item is in, in words for a hint: "Supply run, Long haul".
function L.namesFor(p, item)
    local names = {}
    for _, h in ipairs(L.listsWith(p, item)) do names[#names + 1] = h.list.name end
    return table.concat(names, ", ")
end

--- The pixel icon of a list's kind (L.ICON; one place to swap Design's).
function L.icon(kind) return L.ICON[kind == "outfit" and "outfit" or "loadout"] end

--- The store holds only what the save can keep (strings, numbers, booleans, tables of
-- them). Returns true, or false and the path of the first value that isn't.
function L.check(p)
    local bad = nil
    local function go(t, path, depth)
        if bad or depth > 6 then return end
        for k, v in pairs(t) do
            local tk, tv = type(k), type(v)
            if tk ~= "string" and tk ~= "number" then bad = path .. "[key " .. tk .. "]"; return end
            if tv == "table" then go(v, path .. "." .. tostring(k), depth + 1)
            elseif tv ~= "string" and tv ~= "number" and tv ~= "boolean" then bad = path .. "." .. tostring(k) .. " (" .. tv .. ")"; return end
        end
    end
    local s = L.store(p)
    if s then go(s, L.KEY, 0) end
    return bad == nil, bad
end

-- the item card's mark strip draws its Lists button with the loadout's icon
if ZeD.Atoms and ZeD.Atoms.FLAG_ICON then ZeD.Atoms.FLAG_ICON.lists = L.ICON.loadout end
