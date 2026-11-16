-- ZeD-UI/42/media/lua/client/ZeD/ItemRules.lua
-- ============================================================================
-- ITEM RULES (client; a public hook for add-ons, Nov 15 2026)
--
-- An add-on with a rule about what may go where (ZeD Multi-Slot: a thing goes in only where its shape fits) tells
-- ZeD the rule, so ZeD can say why before a move is tried. The add-on still enforces the rule itself, in the game's
-- own transfer action, in each player's game (client code in 42.22, not shared: a server does not check it); this is only ZeD showing the reason in time.
--
--   ZeD.ItemRules.register(id, rule)                  rule.canPut(item, dest, player, src) -> ok, reason
--   ZeD.ItemRules.unregister(id)
--   ZeD.ItemRules.check(item, dest, player, src) -> ok, reason   every rule in the order registered; first refusal wins
--
-- A rule refuses by returning false (nil or anything else lets the thing go), with the reason as words the player
-- reads ("No room for Hunting Rifle in School Bag"). dest is the container the thing would go into; nil when it is
-- dropped on the ground from a list (the world, not a container). src is where it is now.
-- ZeD asks the rules:
--   - while a mouse drag from a ZeD list is over another container's list: the first refusal's reason is on the help
--     line (with an add-on's grid layout, its canPlace is asked as well, GridLayout.lua)
--   - in its own moves (a drop from a list, the band's Take all / Transfer all / Same type / To floor, the pad's X
--     grab, drops on the container buttons): refused things stay where they are, the others move, and the first
--     reason shows once in the notice over the head (ZeD_Bubbles.note), as ZeD's other "that did not happen" notes.
-- An error in a rule is logged once and the rule lets things go. With no rule registered nothing here runs (filter
-- hands the same list back).
-- ============================================================================

ZeD = ZeD or {}
ZeD.ItemRules = ZeD.ItemRules or {}
local IRu = ZeD.ItemRules

-- (hoisted: the functions below capture these names when they are made)
local _order = {}    -- the rules' ids in the order registered (a list: the order rules are asked in)
local _rules = {}    -- id -> rule
local _logged = {}   -- id -> true once that rule's error was logged

--- Registers a rule under id (a second register under the same id replaces it, keeping its place).
function IRu.register(id, rule)
    if type(rule) ~= "table" or type(rule.canPut) ~= "function" then
        print("ZeD.ItemRules.register(" .. tostring(id) .. "): the rule has no canPut function; not registered")
        return false
    end
    if not _rules[id] then _order[#_order + 1] = id end
    _rules[id] = rule
    _logged[id] = nil
    return true
end

--- Takes the rule registered under id away.
function IRu.unregister(id)
    if not _rules[id] then return end
    _rules[id] = nil
    for i = #_order, 1, -1 do
        if _order[i] == id then table.remove(_order, i) end
    end
end

--- True while any rule is registered.
function IRu.any() return #_order > 0 end

--- Every rule, in the order registered: false and the first refusal's reason, else true.
function IRu.check(item, dest, player, src)
    for i = 1, #_order do
        local id = _order[i]
        local rule = _rules[id]
        local ok, yes, why = pcall(rule.canPut, item, dest, player, src)
        if not ok then
            if not _logged[id] then
                _logged[id] = true
                print("ZeD.ItemRules: " .. tostring(id) .. ".canPut failed; the rule lets things go: " .. tostring(yes))
            end
        elseif yes == false then
            return false, why ~= nil and tostring(why) or nil
        end
    end
    return true, nil
end

--- The rules over a list of things (a drag's): false and the first refusal's reason, else true.
function IRu.checkAll(items, dest, player, src)
    if #_order == 0 or not items then return true, nil end
    for _, item in ipairs(items) do
        local ok, why = IRu.check(item, dest, player, src or item:getContainer())
        if not ok then return false, why end
    end
    return true, nil
end

--- A move ZeD makes: the things the rules let go into dest, in their order. Refused ones are left out (they stay
--- where they are) and the first reason shows once over player's head. Without a rule, or with nothing refused, the
--- same list comes back. src: where they are (nil: each thing's own container).
function IRu.filter(items, dest, player, src)
    if #_order == 0 or not items then return items end
    local kept, first, refused = {}, nil, false
    for _, item in ipairs(items) do
        local ok, why = IRu.check(item, dest, player, src or item:getContainer())
        if ok then
            kept[#kept + 1] = item
        else
            refused = true
            if first == nil then first = why end
        end
    end
    if not refused then return items end
    if first and player and ZeD.Bubbles and ZeD.Bubbles.note then
        pcall(ZeD.Bubbles.note, player:getPlayerNum(), first, "bad")
    end
    return kept
end

-- the last drag over a list that was asked about (the rules are asked once per drag and list, not per frame)
local _ask = { rows = nil, inv = nil, ok = true, why = nil }

--- A list's frame (InventoryRenderer.renderItemList, every column): while a mouse drag from a ZeD list is over this
--- list of another container, the first refusal's reason is on the help line. Nothing without a rule.
function IRu.dragOver(panel, inv)
    if #_order == 0 or not inv then return end
    local GV = panel._gv
    if not (GV and GV.mouseIn) then return end
    local GL = ZeD.GridLayout
    local content, drag = GL.mouseDrag(ZeD.playerNumOf(panel))
    if not content then return end
    local src = content._dragSourceInv
    if src == inv then return end
    if _ask.rows ~= drag.items or _ask.inv ~= inv then
        _ask.rows, _ask.inv = drag.items, inv
        local items = ZeD.InventoryRenderer.dragItems(content, drag.items or {}, src)
        _ask.ok, _ask.why = IRu.checkAll(items, inv, panel._playerObj, src)
    end
    if not _ask.ok and _ask.why then ZeD.Help.set(panel, _ask.why) end
end
