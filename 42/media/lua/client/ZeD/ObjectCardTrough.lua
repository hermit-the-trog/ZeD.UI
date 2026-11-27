-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardTrough.lua
-- ============================================================================
-- OBJECT CARD: FEEDING TROUGH (card definition, client)
-- Vanilla's read-only Feeding Trough panel (a few numbers and three lines of
-- advice, no controller, no distance close) becomes a card in the World
-- window's card drawer. A trough holds food or water, never both:
--   * the tag says Food, Water (Tainted) or Empty;
--   * food: the feed amount and what lies in the trough, each with Take (one)
--     and Take All beside it for a kind of several;
--   * water: the litres on a strip in the water's colour;
--   * Zone: the zone it feeds and how many animals use it, and a warning when
--     it stands outside any animal zone (animals cannot use it there);
--   * Add food from your bags (moved into the trough as the loot window does:
--     Add moves one, Add All beside it the whole kind),
--     Add water (the fluid card aimed at the trough), Pour from a container
--     you carry, Empty (the band at the foot asks first, vanilla's empty).
-- Add food and Add water show only on a trough that can take them.
-- The rule that a trough takes one or the other uses vanilla's own words.
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local function txt(k, fb) local s = getTextOrNull and getTextOrNull(k) return s or fb or k end
local function col(c) return c.r, c.g, c.b end
local function L(v) return string.format("%.1f L", v or 0) end
local function rgb(c) return c and { r = c:getRedFloat(), g = c:getGreenFloat(), b = c:getBlueFloat(), a = 1 } or nil end

local def = { id = "trough" }

local function masterOf(o)
    if not (o and instanceof(o, "IsoFeedingTrough")) then return nil end
    local m = call(o, "getMasterTrough")
    return m or o
end

function def.resolve(player, obj)
    local m = masterOf(obj)
    if not (m and m:getSquare()) then return nil end
    return { obj = m, sq = m:getSquare(), key = OC.keyOf(m:getSquare(), "trough") }
end

function def.valid(t)
    local o = t.obj
    return o ~= nil and o:getSquare() ~= nil and (call(o, "getObjectIndex") or 0) >= 0
end

function def.nearby(player)
    local seen, out = {}, {}
    OC.eachSquare(player, OC.LEASH, function(sq)
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local m = masterOf(objs:get(i))
            if m and not seen[m] then
                seen[m] = true
                local t = def.resolve(player, m)
                if t then out[#out + 1] = t end
            end
        end
    end)
    return OC.sortTargets(out)
end

-- vanilla's tooltip rule for "Tainted"
local function tainted(fc)
    if not (fc and call(fc, "isPoisonous")) then return false end
    local eff = tostring(call(fc, "getPoisonEffect"))
    if eff == "None" then return false end
    local tw = Fluid and Fluid.TaintedWater and call(fc, "getSpecificFluidAmount", Fluid.TaintedWater) or 0
    local total = call(fc, "getAmount") or 0
    if tw > 0 and tw >= total - 0.0001 then
        return SandboxVars and SandboxVars.EnableTaintedWaterText == true
    end
    return true
end

local function wrapFC(fc)
    if not fc then return nil end
    local ok, c = pcall(ISFluidContainer.new, ISFluidContainer, fc)
    return ok and c or nil
end

-- group items by kind: { tex, name, items = {...} }
local function group(list)
    local by, out = {}, {}
    for _, it in ipairs(list) do
        local k = it:getFullType()
        local g = by[k]
        if not g then
            g = { tex = call(it, "getTex"), name = it:getDisplayName(), items = {}, item = it }
            by[k] = g
            out[#out + 1] = g
        end
        g.items[#g.items + 1] = it
    end
    return out
end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
local function moveItems(p, t, items, toTrough)
    if not luautils.walkAdj(p, t.obj:getSquare()) then return end
    local cont = t.obj:getContainer()
    if not cont then return end
    for _, it in ipairs(items) do
        local src = it:getContainer()
        if src then
            if toTrough then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(p, it, src, cont))
            else
                ISTimedActionQueue.add(ISInventoryTransferAction:new(p, it, cont, p:getInventory()))
            end
        end
    end
end

-- The fluid card opens with this card as its way back: its close (back, B) and the end of its pour bring the
-- trough card back to read the new level (QA TG7, Nov 26 2026).
local function openFluid(p, t, fromItemFC)
    local tfc = wrapFC(t.obj:getFluidContainer())
    if not tfc then return end
    local back = OC.current and OC.current(p) or nil
    if fromItemFC then
        OC.open(p, "fluid", { container = wrapFC(fromItemFC), source = true, target = tfc }, back)
    else
        OC.open(p, "fluid", { container = tfc, into = true }, back)
    end
end

-- One press moves one item; the All button beside it moves the kind, as the loot window's one / all. A press used to
-- move every item of the kind, so Add with ten carrots carried put all ten in. (QA TG5; the director's call TG5,
-- Nov 26 2026)
local function moveOne(p, t, items, toTrough)
    local it = items and items[1]
    if it then moveItems(p, t, { it }, toTrough) end
end

-- A pick row with the All button beside its own (a kind of several): the row gives up the button's room and the
-- All button sits in it, its own zone, so the mouse and the pad reach both. Returns the row's height.
local function pickWithAll(card, x, y, w, opts, allLabel, allFid, allHelp, allRun, many)
    local T = ZeD.T
    if not many then return UI.pick(card, x, y, w, opts) end
    local aw = UI.buttonW(allLabel)
    local gap = T.px(6)
    local h = UI.pick(card, x, y, w - aw - gap, opts)
    local bh = T.buttonH - T.px(4)
    local by = y + math.floor((h - bh) / 2)
    UI.button(card, x + w - aw - T.px(2), by, allLabel, { w = aw, h = bh, disabled = opts.enabled == false, fid = allFid,
        body = true, run = allRun, help = allHelp, focus = card.focusOf and card:focusOf(allFid) or nil })
    card:drawRect(x + w - aw - gap, y + h - T.px(1), aw + gap, T.px(1), T.border.a, col(T.border))
    return h
end

-- ---------------------------------------------------------------------------
-- REFRESH
-- ---------------------------------------------------------------------------
function def.refresh(t, player)
    local o = t.obj
    local d = {}
    local okN, nm = pcall(function() return ISWorldObjectContextMenu.getMoveableDisplayName(o) end)
    d.name = (okN and nm and nm ~= "") and nm or (call(o, "getFluidUiName") or txt("ContextMenu_FeedingTrough", "Feeding Trough"))
    d.icon = OC.spriteIcon(o)
    local cont = o:getContainer()
    local items = {}
    if cont then
        local list = cont:getItems()
        for i = 0, list:size() - 1 do items[#items + 1] = list:get(i) end
    end
    d.inside = group(items)
    d.hasFood = #items > 0
    d.feed = call(o, "getCurrentFeedAmount") or 0
    -- the Food tag follows the feed, as the game's window reads it: an emptied bag left in the trough is still an
    -- item but no food (QA TG2, Nov 26 2026); hasFood (any item) still keeps water out, the game's one-or-the-other
    d.fed = d.feed > 0
    local fc = o:getFluidContainer()
    d.fc = fc
    d.water = call(o, "getWater") or 0
    d.maxWater = call(o, "getMaxWater") or 0
    d.hasWater = d.water > 0.0001
    d.waterColor = (fc and not fc:isEmpty()) and rgb(fc:getColor()) or nil
    d.tainted = d.hasWater and tainted(fc)
    d.fluidName = (fc and not fc:isEmpty() and call(fc, "getPrimaryFluid")) and call(call(fc, "getPrimaryFluid"), "getTranslatedName") or nil

    -- zone and the animals using it
    local sq = o:getSquare()
    local zone = DesignationZoneAnimal and DesignationZoneAnimal.getZone(sq:getX(), sq:getY(), sq:getZ())
    d.zone = zone
    d.zoneName = zone and call(zone, "getName") or nil
    local linked = call(o, "getLinkedAnimals")
    d.linked = linked and linked:size() or 0

    -- feed you carry that the trough takes
    local feed = {}
    if cont then
        local all = player:getInventory():getAllEvalRecurse(function(it)
            if it:isEquipped() then return false end
            local ok, v = pcall(function() return o:isItemAllowedInContainer(cont, it) end)
            return ok and v == true
        end)
        for i = 0, all:size() - 1 do feed[#feed + 1] = all:get(i) end
    end
    d.feedRows = group(feed)
    for _, g in ipairs(d.feedRows) do g.where = OC.whereOf(g.item, player) end

    -- water you carry that can pour into it
    d.pourRows = {}
    if fc and not d.hasFood then
        local all = player:getInventory():getAllEvalRecurse(function(it)
            local ifc = it:getFluidContainer()
            if not (ifc and not ifc:isEmpty()) then return false end
            local ok, v = pcall(FluidContainer.CanTransfer, ifc, fc)
            return ok and v == true
        end)
        for i = 0, all:size() - 1 do
            local it = all:get(i)
            local ifc = it:getFluidContainer()
            d.pourRows[#d.pourRows + 1] = { item = it, fc = ifc, tex = call(it, "getTex"), name = it:getDisplayName(),
                where = OC.whereOf(it, player) .. " " .. DOT .. " " .. L(ifc:getAmount()) }
        end
    end
    t.d = d

    -- verbs: one or the other, in vanilla's words
    -- a trough holds food or water, never both: with water in it there is no adding food, with food
    -- no adding water (vanilla's rule; those verbs are gone), and Empty is for water
    local verbs = {}
    local foodOK = not d.hasWater and #d.feedRows > 0 and cont ~= nil
    local waterOK = not d.hasFood and fc ~= nil
    verbs[#verbs + 1] = { id = "food", label = ZeD.tr("UI_ZeD_Trough_AddFood"), primary = not d.hasWater, enabled = foodOK, jump = "trough:feed:1",
        sensible = not d.hasWater, needs = ZeD.tr("UI_ZeD_Trough_NeedsFeed"), hint = ZeD.tr("UI_ZeD_Trough_HintFood"),
        help = ZeD.tr("UI_ZeD_Trough_HelpFood") }
    verbs[#verbs + 1] = { id = "water", label = ZeD.tr("UI_ZeD_Trough_AddWater"), primary = d.hasWater, enabled = waterOK,
        sensible = not d.hasFood, help = ZeD.tr("UI_ZeD_Trough_HelpWater"),
        run = function(p, tt) openFluid(p, tt) end }
    if d.hasWater then
        local q = ZeD.tr("UI_ZeD_Trough_QEmpty", L(d.water), string.lower(d.fluidName or ZeD.tr("UI_ZeD_Trough_WaterWord")))
        verbs[#verbs + 1] = { id = "empty", label = txt("Fluid_Empty", "Empty"), danger = true, confirm = q,
            help = ZeD.tr("UI_ZeD_Trough_HelpEmpty"),
            enabled = fc ~= nil and call(fc, "canPlayerEmpty") ~= false,
            run = function(p, tt) ISWorldObjectContextMenu.onFluidEmpty(p:getPlayerNum(), tt.obj:getFluidContainer()) end }
    end
    t.verbs = verbs
end

function def.title(t) return t.d and t.d.name or txt("ContextMenu_FeedingTrough", "Feeding Trough") end
function def.icon(t) return t.d and t.d.icon or nil end
-- the state tag: its words, the colour of its square mark (none for a plain tag), and a
-- mark colour of its own (the water's colour)
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.fed then return ZeD.tr("UI_ZeD_Trough_PillFood"), T.positive end
    if d.hasWater then
        if d.tainted then return txt("Tooltip_tainted", "Tainted"), T.danger end
        return ZeD.tr("Fluid_Name_Water"), T.textDim, d.waterColor
    end
    return ZeD.tr("Fluid_Empty"), T.textDim
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
local function bigReadout(card, x, y, value, unit)
    local T, tm = ZeD.T, ZeD.TM
    local bw = UI.big(card, value, x, y, 34, T.text) or tm:MeasureStringX(T.fontF4, value)
    local h = T.px(34)
    local f1 = T.fontF1
    card:drawText(unit, x + bw + T.px(8), y + h - tm:getFontHeight(f1) - T.px(4), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f1)
    return h
end

-- the water's level: the library's framed strip in the water's colour, its name under it
local function gauge(card, x, y, w, frac, c, label)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.fillBarH
    ZeD.Atoms.drawFillBar(card, x, y, w, math.max(0, math.min(1, frac)), false, c, h, label)   -- ("Water 64%")
    local f3 = T.fontF3
    local ly = y + h + T.px(3)
    if label then ZeD.Atoms.drawTextRight(card, label, x + w, ly, f3, T.text) end
    return h + T.px(3) + tm:getFontHeight(f3)
end

function def.body(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    if not (d and def.valid(t)) then return 0 end
    local y0 = y
    local gap = T.px(8)

    if not d.zone then
        y = y + UI.warn(card, x, y, w, ZeD.tr("UI_ZeD_Trough_NoZoneWarn")) + gap
    end
    if d.hasFood then
        y = y + bigReadout(card, x, y, string.format("%.1f", d.feed), ZeD.tr("UI_ZeD_Trough_Feed")) + gap
    elseif d.hasWater then
        y = y + bigReadout(card, x, y, string.format("%.1f", d.water), ZeD.tr("UI_ZeD_Trough_WaterUnit", L(d.maxWater), d.fluidName or ZeD.tr("UI_ZeD_Trough_WaterWord"))) + T.px(4)
        local lbl = (d.fluidName or ZeD.tr("UI_ZeD_Trough_WaterWord")) .. (d.tainted and (" (" .. txt("Tooltip_tainted", "Tainted") .. ")") or "")
        y = y + gauge(card, x, y, w, d.maxWater > 0 and (d.water / d.maxWater) or 0, d.waterColor or T.info, lbl) + gap
    end

    -- what lies in it
    if #d.inside > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Trough_InTrough"), tostring(#d.inside))
        for i, g in ipairs(d.inside) do
            local gg = g
            y = y + pickWithAll(card, x, y, w, { tex = g.tex, name = g.name .. (#g.items > 1 and (" " .. DOT .. " " .. #g.items) or ""),
                button = getText("ContextMenu_Take"), fid = "trough:take:" .. i, help = ZeD.tr("UI_ZeD_Trough_HelpTake", g.name),
                run = function(c, p) moveOne(p, t, gg.items, false) end },
                ZeD.tr("IGUI_invpage_Loot_all"), "trough:takeall:" .. i, ZeD.tr("UI_ZeD_Trough_HelpTakeAll", g.name),
                function(c, p) moveItems(p, t, gg.items, false) end, #g.items > 1)
        end
        y = y + gap
    end

    -- zone
    y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Trough_Zone"), d.zone and ZeD.tr("UI_ZeD_Trough_ZoneLinked") or ZeD.tr("IGUI_None"))
    y = y + UI.pair(card, x, y, w, ZeD.tr("UI_ZeD_Trough_LinkedTo"), d.zoneName or txt("IGUI_Animal_TroughNotLinked", "None"),
        ZeD.tr("UI_ZeD_Trough_Animals"), d.zone and ZeD.tr("UI_ZeD_Trough_UseIt", d.linked) or nil)
    y = y + gap

    -- feed you carry
    if not d.hasWater then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Trough_YourFeed"), tostring(#d.feedRows))
        if #d.feedRows == 0 then
            y = y + ZeD.Molecules.drawEmptyLine(card, x + T.px(2), y + T.px(8), w - T.px(4), ZeD.tr("UI_ZeD_Trough_NothingToAdd")) + T.px(12)
        end
        for i, g in ipairs(d.feedRows) do
            local gg = g
            y = y + pickWithAll(card, x, y, w, { tex = g.tex, name = g.name .. (#g.items > 1 and (" " .. DOT .. " " .. #g.items) or ""),
                where = g.where, button = getText("UI_btn_add"), fid = "trough:feed:" .. i, help = ZeD.tr("UI_ZeD_Trough_HelpFeed", g.name),
                run = function(c, p) moveOne(p, t, gg.items, true) end },
                ZeD.tr("ContextMenu_AddAll"), "trough:feedall:" .. i, ZeD.tr("UI_ZeD_Trough_HelpFeedAll", g.name),
                function(c, p) moveItems(p, t, gg.items, true) end, #g.items > 1)
        end
        y = y + gap
    end

    -- water you carry
    if not d.hasFood and #d.pourRows > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Fluid_YourContainers"), tostring(#d.pourRows))
        for i, r in ipairs(d.pourRows) do
            local rr = r
            y = y + UI.pick(card, x, y, w, { tex = r.tex, name = r.name, where = r.where, button = getText("Fluid_Transfer"), fid = "trough:pour:" .. i,
                help = ZeD.tr("UI_ZeD_Trough_HelpPour", r.name), run = function(c, p) openFluid(p, t, rr.fc) end })
        end
    end
    return y - y0
end

OC.register(def)
print("[ZeD] ObjectCardTrough: trough card loaded")
return def
