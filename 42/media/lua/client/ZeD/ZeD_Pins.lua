-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Pins.lua
-- ============================================================================
-- PINS ON THE CHARACTER WINDOW'S TITLE BAR (the director, Nov 4 2026: "option 2. Include a bunch of options to
-- start", growing from players' requests; mockup ZeDUI/mockups/zed_title_pins_v1.html, "Three, build it").
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
-- Kept in the player's modData ZeD_Pins = { { k, id }, ... } oldest first (ZeD_PinnedSkills, the old skill pins,
-- read once into it).
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
local function itemOf(p, id)
    local ok, it = pcall(function() return p:getInventory():getItemWithIDRecursiv(tonumber(id)) end)
    return ok and it or nil
end
local function nameOf(p, e)
    if e.k == "skill" then
        local pd = ZeD.SkillsTab and ZeD.SkillsTab.getPinData and ZeD.SkillsTab.getPinData(p, e.id)
        return pd and pd.name or tostring(e.id)
    end
    local it = itemOf(p, e.id)
    return it and it:getDisplayName() or e.name or "?"
end

-- pins or unpins; a pin past MAX takes off the oldest and says which
function P.toggle(p, k, id, name)
    local L = list(p)
    local i = P.find(p, k, id)
    if i then table.remove(L, i); return false end
    L[#L + 1] = { k = k, id = id, name = name }
    if #L > P.MAX then
        local gone = table.remove(L, 1)
        local pn = p:getPlayerNum()
        local msg = ZeD.tr("UI_ZeD_Pin_Replaced", tostring(name or nameOf(p, L[#L])), tostring(gone.name or nameOf(p, gone)), P.MAX)
        if ZeD.Bubbles and ZeD.Bubbles.note then pcall(ZeD.Bubbles.note, pn, msg, nil) end
    end
    return true
end

-- the skill names pinned (the Skills tab marks their rows)
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

-- a name short enough for the title bar (QA, Nov 4 2026: with a book's whole title only one pin fitted): the part
-- before a colon or a bracket, at most SHORT letters
local SHORT = 16
local function shortName(n)
    n = tostring(n or "")
    local head = n:match("^([^:%(]+)")
    if head and head:gsub("%s+$", "") ~= "" then n = head:gsub("%s+$", "") end
    if #n > SHORT then n = n:sub(1, SHORT - 1):gsub("%s+$", "") .. "..." end
    return n
end
P.shortName = shortName

-- the title bar's entries for the pins: { text, color }, oldest first
function P.stats(p)
    local T = ZeD.T
    local out = {}
    for _, e in ipairs(list(p)) do
        local text, color = nil, nil
        if e.k == "skill" then
            local pd = ZeD.SkillsTab and ZeD.SkillsTab.getPinData and ZeD.SkillsTab.getPinData(p, e.id)
            if pd then
                if pd.level >= 10 then text, color = ZeD.tr("UI_ZeD_Char_PinMax", pd.name), T.positive
                else text, color = ZeD.tr("UI_ZeD_Char_PinLevel", pd.name, pd.level, pd.xpInLevel .. "/" .. pd.xpForLevel), T.accent end
            end
        else
            local it = itemOf(p, e.id)
            if it then
                local name = shortName(it:getDisplayName())
                pcall(function()
                    if e.k == "book" then
                        local n, r = it:getNumberOfPages() or 0, it:getAlreadyReadPages() or 0
                        text = ZeD.tr("UI_ZeD_Pin_Of", name, r, n)
                        color = (n > 0 and r >= n) and T.positive or T.accent
                    elseif e.k == "fluid" then
                        local fc = it:getFluidContainer()
                        local a, c = fc:getAmount() or 0, fc:getCapacity() or 0
                        text = ZeD.tr("UI_ZeD_Pin_Litres", name, string.format("%.1f", a), string.format("%.1f", c))
                        color = (c > 0 and a / c < 0.25) and T.warning or T.info
                    elseif e.k == "uses" then
                        local u = it:getCurrentUsesFloat() or 0
                        text = ZeD.tr("UI_ZeD_Pin_Pct", name, math.floor(u * 100 + 0.5))
                        color = (u < 0.25) and T.warning or T.info
                    elseif e.k == "cond" then
                        local c, m = it:getCondition() or 0, it:getConditionMax() or 1
                        text = ZeD.tr("UI_ZeD_Pin_Of", name, c, m)
                        color = (c <= 0 and T.danger) or ((c / m <= 0.25) and T.warning) or T.positive
                    end
                end)
            end
        end
        if text then out[#out + 1] = { text = text, color = color } end
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

-- a skill row's menu (the Skills tab: right-click, or X / A on a controller), at screen x, y
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
