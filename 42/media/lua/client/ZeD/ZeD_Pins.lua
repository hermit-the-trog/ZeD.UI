-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Pins.lua
-- ============================================================================
-- PINS ON THE CHARACTER WINDOW'S TITLE BAR. Client; a data module with no UI of its own: the Character window's
-- title bar draws the pins (P.stats), the Skills tab and an item's right-click menu set them. The kinds below are a
-- starting set, to grow with what players ask for.
-- Pinned from the right-click menu ("Pin to title bar"; X on a controller), never a plain click. Three at most: a
-- fourth replaces the oldest, said in a note over the head (ZeD_Bubbles.note), never a pop-up. Every pin is a number
-- the game already shows you (nothing hidden, vanilla's stakes kept).
--
--   skill     a skill's level and XP in it                     Carpentry 3 | 120/300
--   book      the book you read: pages read of its pages       Carpentry Vol. 2 | 48/220
--   fluid     a container of liquid: how full                  Water Bottle | 0.6/1.0 L
--   uses      a battery, a lighter, thread: how much is left   Flashlight | 62%
--   cond      a weapon or tool: its condition                  Axe | 7/10
-- Items are found by their id in what the player carries; one put down shows nothing until it is back.
-- Kept in the player's modData ZeD_Pins = { { k, id, name, ft }, ... } oldest first; ft, an item's full type, finds
-- the same kind of item when its id is gone (ZeD_PinnedSkills, the old skill pins, is read once into it).
-- ============================================================================

ZeD = ZeD or {}
ZeD.Pins = ZeD.Pins or {}
local P = ZeD.Pins

P.MAX = 3

local function list(p)
    if not p then return {} end
    local md = p:getModData()
    if not md.ZeD_Pins then
        md.ZeD_Pins = {}
        for _, name in ipairs(md.ZeD_PinnedSkills or {}) do md.ZeD_Pins[#md.ZeD_Pins + 1] = { k = "skill", id = name } end
        md.ZeD_PinnedSkills = nil
    end
    return md.ZeD_Pins
end
P.list = list

function P.find(p, k, id)
    for i, e in ipairs(list(p)) do if e.k == k and tostring(e.id) == tostring(id) then return i end end
    return nil
end
function P.isPinned(p, k, id) return P.find(p, k, id) ~= nil end

-- the name a pin shows for itself (an item's display name, a skill's)
-- (the title bar asks every frame, so the guarded calls are named
-- functions, not a closure per pin per frame)
local function carriedById(p, id) return p:getInventory():getItemWithIDRecursiv(tonumber(id)) end
local function carriedByType(p, ft) return p:getInventory():getFirstTypeRecurse(ft) end
local function itemOf(p, id, e)
    local ok, it = pcall(carriedById, p, id)
    if ok and it then return it end
    -- (the same kind of thing you carry, when its id is not found: ids may not survive the game loading again)
    if e and e.ft then
        local ok2, it2 = pcall(carriedByType, p, e.ft)
        if ok2 and it2 then e.id = it2:getID(); return it2 end
    end
    return nil
end
-- the name a pin shows for itself (an item's display name, a skill's)
local function nameOf(p, e)
    if e.k == "skill" then
        local pd = ZeD.SkillsTab and ZeD.SkillsTab.getPinData and ZeD.SkillsTab.getPinData(p, e.id)
        return pd and pd.name or tostring(e.id)
    end
    local it = itemOf(p, e.id)
    return it and it:getDisplayName() or e.name or "?"
end

--- Pin or unpin (k, id) for player p; name, when given, is the pin's words in the note. A pin past MAX takes off
--- the oldest and says which. Returns true when it pinned, false when it unpinned.
function P.toggle(p, k, id, name)
    local L = list(p)
    local i = P.find(p, k, id)
    if i then table.remove(L, i); return false end
    local ft = nil
    if k ~= "skill" then
        local it = itemOf(p, id)
        if it then pcall(function() ft = it:getFullType() end) end
    end
    L[#L + 1] = { k = k, id = id, name = name, ft = ft }
    if #L > P.MAX then
        local gone = table.remove(L, 1)
        local pn = p:getPlayerNum()
        local msg = ZeD.tr("UI_ZeD_Pin_Replaced", tostring(name or nameOf(p, L[#L])), tostring(gone.name or nameOf(p, gone)), P.MAX)
        if ZeD.Bubbles and ZeD.Bubbles.note then pcall(ZeD.Bubbles.note, pn, msg, nil) end
    end
    return true
end

--- The skill names pinned (the Skills tab marks their rows).
function P.skillNames(p)
    local out = {}
    for _, e in ipairs(list(p)) do if e.k == "skill" then out[#out + 1] = e.id end end
    return out
end

-- what kind of pin an item can be (nil: none)
local function kindOf(item)
    if not item then return nil end
    local ok, r = pcall(function()
        if instanceof(item, "Literature") and (item:getNumberOfPages() or 0) > 0 then return "book" end
        local fc = nil
        pcall(function() fc = item:getFluidContainer() end)
        if fc and (fc:getCapacity() or 0) > 0 then return "fluid" end
        if instanceof(item, "DrainableComboItem") then return "uses" end
        if (item:getConditionMax() or 0) > 1 and (instanceof(item, "HandWeapon") or item:getCategory() == "Weapon") then return "cond" end
        return nil
    end)
    return ok and r or nil
end
P.kindOf = kindOf

-- a name short enough for the title bar (with a book's whole title only one pin would fit): the part before a colon
-- or a bracket, at most SHORT letters
local SHORT = 16
local function shortName(n, max)
    max = max or SHORT
    n = tostring(n or "")
    local head = n:match("^([^:%(]+)")
    if head and head:gsub("%s+$", "") ~= "" then n = head:gsub("%s+$", "") end
    if #n > max then n = n:sub(1, max - 1):gsub("%s+$", "") .. "..." end
    return n
end
P.shortName = shortName

-- A pin's words with a name n (nil: the number alone): mode "max" (a skill at 10), "level" (a skill: pd the
-- skill's pin data) or "item" (key a1 a2: the item's line)
local function pinForm(mode, pd, key, a1, a2, n)
    if mode == "max" then return n and ZeD.tr("UI_ZeD_Char_PinMax", n) or "10" end
    if mode == "level" then
        if n then return ZeD.tr("UI_ZeD_Char_PinLevel", n, pd.level, pd.xpInLevel .. "/" .. pd.xpForLevel) end
        return ZeD.tr("UI_ZeD_Pin_Of", pd.level, pd.xpInLevel, pd.xpForLevel)
    end
    local t = ZeD.tr(key, n or "", a1, a2)
    if not n then t = t:gsub("^%s*|%s*", "") end
    return t
end

-- an item pin's numbers: key, a1, a2, color (key nil: a kind with none); run guarded, as an item may lack a part
local function itemLine(k, it, T)
    local key, a1, a2, color
    if k == "book" then
        local n, r = it:getNumberOfPages() or 0, it:getAlreadyReadPages() or 0
        key, a1, a2 = "UI_ZeD_Pin_Of", r, n
        color = (n > 0 and r >= n) and T.positive or T.accent
    elseif k == "fluid" then
        local fc = it:getFluidContainer()
        local am, c = fc:getAmount() or 0, fc:getCapacity() or 0
        key, a1, a2 = "UI_ZeD_Pin_Litres", string.format("%.1f", am), string.format("%.1f", c)
        color = (c > 0 and am / c < 0.25) and T.warning or T.info
    elseif k == "uses" then
        local u = it:getCurrentUsesFloat() or 0
        key, a1 = "UI_ZeD_Pin_Pct", math.floor(u * 100 + 0.5)
        color = (u < 0.25) and T.warning or T.info
    elseif k == "cond" then
        local c, m = it:getCondition() or 0, it:getConditionMax() or 1
        key, a1, a2 = "UI_ZeD_Pin_Of", c, m
        color = (c <= 0 and T.danger) or ((c / m <= 0.25) and T.warning) or T.positive
    end
    return key, a1, a2, color
end

-- the title bar's entries for the pins: { text, color }, oldest first
-- (asked every frame by the title bar, so no closure per pin: the words come
-- from pinForm, the item's numbers from itemLine)
function P.stats(p)
    local T = ZeD.T
    local out = {}
    for _, e in ipairs(list(p)) do
        -- the pin's words with a name (nil: the number alone); the title bar takes the longest form that
        -- fits, then shorter ones (QA, Nov 4 2026: pins were dropped where a shorter form would have fitted)
        local mode, pd, key, a1, a2, color, full = nil, nil, nil, nil, nil, nil, nil
        if e.k == "skill" then
            pd = ZeD.SkillsTab and ZeD.SkillsTab.getPinData and ZeD.SkillsTab.getPinData(p, e.id)
            if pd then
                full = pd.name
                if pd.level >= 10 then
                    color = T.positive
                    mode = "max"
                else
                    color = T.accent
                    mode = "level"
                end
            end
        else
            local it = itemOf(p, e.id, e)
            if it then
                full = it:getDisplayName()
                local ok, k1, b1, b2, c1 = pcall(itemLine, e.k, it, T)
                if ok and k1 then mode, key, a1, a2, color = "item", k1, b1, b2, c1 end
            end
        end
        if mode then
            local text = pinForm(mode, pd, key, a1, a2, shortName(full, SHORT))
            local alts = { pinForm(mode, pd, key, a1, a2, shortName(full, 8)), pinForm(mode, pd, key, a1, a2, nil) }
            out[#out + 1] = { text = text, color = color, alts = alts }
        end
    end
    return out
end

-- the right-click menu of an item the player carries: Pin to title bar / Unpin from title bar
local function onFillInventory(pn, context, rawItems)
    if ZeD.Safe and ZeD.Safe.on() then return end
    local p = getSpecificPlayer(pn)
    if not (p and context and rawItems) then return end
    local ok, items = pcall(ISInventoryPane.getActualItems, rawItems)
    if not ok or not items or #items ~= 1 then return end
    local it = items[1]
    local k = kindOf(it)
    if not k then return end
    local okc, carried = pcall(function() return it:isInPlayerInventory() end)
    if okc and carried == false then return end
    local id = it:getID()
    local pinned = P.isPinned(p, k, id)
    context:addOption(ZeD.tr(pinned and "UI_ZeD_Pin_Unpin" or "UI_ZeD_Pin_Pin"), p, function() P.toggle(p, k, id, it:getDisplayName()) end)
end
P.onFillInventory = onFillInventory

--- A skill row's menu (the Skills tab: right-click, or X / A on a controller), at screen x, y.
function P.skillMenu(pn, skillName, label, x, y)
    local p = getSpecificPlayer(pn)
    if not p or not ISContextMenu then return end
    local ctx = ISContextMenu.get(pn, x or getMouseX(), y or getMouseY())
    local pinned = P.isPinned(p, "skill", skillName)
    ctx:addOption(ZeD.tr(pinned and "UI_ZeD_Pin_Unpin" or "UI_ZeD_Pin_Pin"), p, function() P.toggle(p, "skill", skillName, label) end)
    if JoypadState.players[pn + 1] then
        ctx.origin = nil
        ctx.mouseOver = 1
        setJoypadFocus(pn, ctx)
    end
end

if not _G._zedPinsHooked then
    _G._zedPinsHooked = true
    Events.OnFillInventoryObjectContextMenu.Add(function(...) return ZeD.Pins.onFillInventory(...) end)
end

return P
