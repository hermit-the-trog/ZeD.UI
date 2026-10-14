-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardFluid.lua
-- ============================================================================
-- OBJECT CARD: FLUIDS (HOOK_MAP rows 8 and 9; mockup zed_fluids_v1.html)
-- Vanilla's "Transfer Liquid" and "Container Info" windows become one fluid
-- card in the World window's card drawer:
--   * two tanks, POUR FROM / POUR INTO, filled in each liquid's colour, with
--     a hatched band for what leaves and what arrives and a line where each
--     ends up;
--   * one amount control (catalog M16 slider, 1/4, 1/2, ALL) from nothing to
--     vanilla's Max Pour (the smaller of what the left holds and the room in
--     the right, rounded by FluidUtil.roundTransfer), starting at the most;
--   * LIQUIDS: what the left container holds, each with its share; the red
--     "Tainted" flag where vanilla's tooltip shows it (poison level only in
--     debug, as vanilla);
--   * YOUR CONTAINERS: every liquid container you carry (and the world
--     container the card opened on, pinned), each with FROM / INTO and a tag
--     for what a pour into it would do, from vanilla's own refusal reasons;
--   * verbs POUR (vanilla's ISFluidTransferAction), SWITCH, EMPTY (footer
--     confirm, vanilla's empty action); while it pours, a progress band with
--     STOP.
-- The card follows a world container within OC.LEASH tiles; a pour between
-- your own containers has no tile and no leash.
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local TANK_W, TANK_H = 60, 104   -- design units
local VESSEL_W = 150
local STEP = 0.05                -- controller step on the amount (share of Max Pour)

local function txt(k, fb) local s = getTextOrNull and getTextOrNull(k) return s or fb or k end

-- "0.25 L" under 10 L, "96.0 L" under 100 L, "160 L" above
local function L(v)
    v = v or 0
    if v >= 100 then return string.format("%.0f L", v) end
    if v >= 10 then return string.format("%.1f L", v) end
    return string.format("%.2f L", v)
end

local function rgb(c)
    if not c then return nil end
    local r, g, b = call(c, "getRedFloat"), call(c, "getGreenFloat"), call(c, "getBlueFloat")
    if not r then return nil end
    return { r = r, g = g, b = b, a = 1 }
end

local ALL_FLUIDS = nil
local function allFluids()
    if not ALL_FLUIDS then
        ALL_FLUIDS = {}
        local list = Fluid.getAllFluids()
        for i = 0, list:size() - 1 do ALL_FLUIDS[#ALL_FLUIDS + 1] = list:get(i) end
    end
    return ALL_FLUIDS
end

-- The liquids in a container, largest first.
local function liquidsOf(fc)
    local out = {}
    if not fc or fc:isEmpty() then return out end
    for _, f in ipairs(allFluids()) do
        local a = fc:getSpecificFluidAmount(f)
        if a and a > 0.0001 then
            out[#out + 1] = { fluid = f, amt = a, name = f:getTranslatedName(), color = rgb(f:getColor()),
                tainted = tostring(f:getFluidType()) == "TaintedWater", poison = f:isPoisonous() }
        end
    end
    table.sort(out, function(a, b) return a.amt > b.amt end)
    return out
end

-- Vanilla's tooltip shows "Tainted" in red when the container is poisonous
-- and either holds a poisonous liquid other than tainted water, or holds
-- tainted water with the sandbox's tainted-water text on.
local function taintedShown(fc, liquids)
    if not (fc and fc:isPoisonous()) then return false end
    if tostring(fc:getPoisonEffect()) == "None" then return false end
    for _, l in ipairs(liquids) do
        if (not l.tainted) and l.poison then return true end
    end
    return fc:isTainted() and SandboxVars and SandboxVars.EnableTaintedWaterText == true
end

local function nameOf(c)
    local owner = c and c:getOwner()
    if owner and instanceof(owner, "InventoryItem") then return owner:getDisplayName() end
    local fc = c and c:getFluidContainer()
    local n = fc and call(fc, "getTranslatedContainerName")
    if n and n ~= "" then return n end
    return (owner and call(owner, "getTileName")) or "Container"
end

local function iconOf(c)
    local owner = c and c:getOwner()
    if owner and instanceof(owner, "InventoryItem") then return owner:getTex() end
    local tile = owner and call(owner, "getSpriteName")
    local tex = tile and getTexture(tile)
    return tex and (call(tex, "splitIcon") or tex) or nil
end

-- "Water", or vanilla's "Mixture" when several liquids share the container
-- (the engine's UI name also carries the container and "(Tainted)")
local function fluidLabel(liquids)
    if #liquids == 0 then return nil end
    if #liquids == 1 then return liquids[1].name end
    return txt("Fluid_Mixture", "Mixture")
end

local function sameContainer(a, b)
    return a ~= nil and b ~= nil and a:getFluidContainer() == b:getFluidContainer()
end

-- Every liquid container the player may pour from or into (vanilla's rule:
-- in the inventory, bags included, and allowed to be emptied).
local function carried(player)
    local out = {}
    local list = player:getInventory():getAllEvalRecurse(function(it)
        local fc = it:getFluidContainer()
        return fc ~= nil and fc:canPlayerEmpty()
    end)
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        out[#out + 1] = { c = ISFluidContainer:new(it:getFluidContainer()), item = it,
            key = "i" .. tostring(it:getID()), where = OC.whereOf(it, player) }
    end
    table.sort(out, function(a, b) return a.item:getDisplayName() < b.item:getDisplayName() end)
    return out
end

-- Vanilla's refusal reason -> the row tag
local REASONS = nil
local function tagForReason(reason)
    if not REASONS then
        REASONS = {
            [txt("Fluid_Reason_Target_Full", "Container is full.")] = { "FULL", "dim" },
            [txt("Fluid_Reason_Mixing_Locked", "Cannot mix these liquids.")] = { "WON'T MIX", "dng" },
            [txt("Fluid_Reason_Target_Filter", "Cannot pour this liquid into target container.")] = { "WON'T TAKE", "dng" },
            [txt("Fluid_Reason_Target_Locked", "Cannot pour into target container.")] = { "WON'T TAKE", "dng" },
        }
    end
    local r = reason and REASONS[reason]
    if r then return r[1], r[2] end
    return nil, nil
end

-- The engine refuses any pour into a container you carry while your
-- inventory is over its limit, then reports its last reason ("Cannot mix
-- these liquids."). Name the real cause instead.
local TOO_FULL = "You carry too much to pour into a container in your bags."
local function carriedTarget(fc, player)
    local o = fc and fc:getOwner()
    return o ~= nil and instanceof(o, "InventoryItem") and o:isInPlayerInventory()
end
local function reasonFor(ffc, fc, player)
    if carriedTarget(fc, player) and call(player, "hasFullInventory") == true then return TOO_FULL end
    return FluidContainer.GetTransferReason(ffc, fc)
end

-- Progress of the queued pour, 0..1. The Java action exists only once the
-- pour has started (after any walk), and getJobDelta reads it unguarded.
local function jobDelta(act)
    if not (act and act.action) then return 0 end
    local ok, v = pcall(act.getJobDelta, act)
    return (ok and v) or 0
end

local def = { id = "fluid" }

-- arg = { container = ISFluidContainer, source = bool, info = bool }
function def.resolve(player, arg)
    local c = arg and arg.container
    if not (c and ISFluidUtil.validateContainer(c) and c:isValid()) then return nil end
    local t = { key = "fluid", frac = 1 }
    if not c:isItem() then
        t.pinned = c
        local owner = c:getOwner()
        t.sq = owner and call(owner, "getSquare") or nil
    end
    local fc = c:getFluidContainer()
    -- vanilla: the opened container goes left when it is the source or holds
    -- something; Container Info always looks at it on the left. A ZeD card
    -- can aim it: into = true puts it on the right (the trough's ADD WATER),
    -- target = a second container to pour into (the trough's POUR rows).
    if arg.into then t.into = c
    elseif arg.info or arg.source or not fc:isEmpty() then t.from = c else t.into = c end
    if arg.target and ISFluidUtil.validateContainer(arg.target) then
        t.into = arg.target
        if not arg.target:isItem() then
            t.pinned = arg.target
            local owner = arg.target:getOwner()
            t.sq = owner and call(owner, "getSquare") or nil
        end
    end
    return t
end

function def.valid(t)
    if t.pinned and not ISFluidUtil.validateContainer(t.pinned) then return false end
    return true
end

-- ---------------------------------------------------------------------------
-- REFRESH
-- ---------------------------------------------------------------------------
local function setSides(t, from, into)
    t.from, t.into = from, into
    t.frac = 1
    t._refreshT = OC.REFRESH
end

function def.refresh(t, player)
    -- a side whose item left the inventory empties
    if t.from and not ISFluidUtil.validateContainer(t.from) then t.from = nil end
    if t.into and not ISFluidUtil.validateContainer(t.into) then t.into = nil end
    local d = {}
    local ffc = t.from and t.from:getFluidContainer()
    local ifc = t.into and t.into:getFluidContainer()

    -- pouring?
    d.pouring = t.action ~= nil and ISTimedActionQueue.hasAction(t.action)
    if not d.pouring then t.action = nil end

    -- rows: the pinned world container, then what you carry
    local rows = {}
    if t.pinned then
        rows[1] = { c = t.pinned, key = "pin", pin = true,
            where = "NEARBY" }
        if t.sq then
            local n = math.floor(OC.squareDist(player, t.sq) + 0.5)
            rows[1].where = "NEARBY " .. DOT .. " " .. tostring(n) .. (n == 1 and " TILE" or " TILES")
        end
    end
    for _, r in ipairs(carried(player)) do rows[#rows + 1] = r end
    for _, r in ipairs(rows) do
        local fc = r.c:getFluidContainer()
        r.fc = fc
        r.name = nameOf(r.c)
        r.tex = iconOf(r.c)
        r.amt, r.cap = fc:getAmount(), fc:getCapacity()
        r.hidden = fc:isHiddenAmount()
        r.color = (not fc:isEmpty()) and rgb(fc:getColor()) or nil
        r.isFrom = sameContainer(r.c, t.from)
        r.isInto = sameContainer(r.c, t.into)
        r.canFrom = (not r.isFrom) and r.amt > 0
        r.canInto = not r.isInto and not r.isFrom   -- SWITCH swaps the two sides
        r.tag, r.tagK = nil, nil
        if ffc and not r.isFrom then
            if FluidContainer.CanTransfer(ffc, fc) then
                if fc:isEmpty() then r.tag = "EMPTY"
                else
                    local prim = ffc:getPrimaryFluid()
                    if prim and ffc:isPureFluid(prim) and fc:isPureFluid(prim) then r.tag = "SAME"
                    else r.tag, r.tagK = "MIXES", "warn" end
                end
            else
                local why = reasonFor(ffc, fc, player)
                if why == TOO_FULL then r.tag, r.tagK = "TOO HEAVY", "dng"
                else r.tag, r.tagK = tagForReason(why) end
                r.canInto = false
            end
        elseif not r.isFrom and fc:isEmpty() then
            r.tag = "EMPTY"
        end
        if d.pouring then r.canFrom, r.canInto = false, false end
    end
    d.rows = rows

    -- the pour
    d.can = ffc ~= nil and ifc ~= nil and FluidContainer.CanTransfer(ffc, ifc)
    d.max = 0
    if d.can then
        d.max = FluidUtil.roundTransfer(math.min(ffc:getAmount(), ifc:getCapacity() - ifc:getAmount()))
    end
    d.reason = (ffc and ifc and not d.can) and reasonFor(ffc, ifc, player) or nil

    -- what the left holds
    d.fromLiquids = liquidsOf(ffc)
    d.intoLiquids = liquidsOf(ifc)
    d.tainted = ffc ~= nil and taintedShown(ffc, d.fromLiquids)
    d.poison = nil
    if ffc and getDebug() and ffc:isPoisonous() then
        local eff = tostring(ffc:getPoisonEffect())
        if eff ~= "None" then d.poison = txt("Fluid_Poison_" .. eff, eff) end
    end
    d.fluid = fluidLabel(d.fromLiquids)
    d.fluidColor = ffc and (not ffc:isEmpty()) and rgb(ffc:getColor()) or nil
    d.fromName = t.from and nameOf(t.from)
    d.intoName = t.into and nameOf(t.into)
    d.icon = iconOf(t.from or t.into)
    t.d = d

    -- verbs
    local verbs, needs = {}, {}
    local pourOK = d.can and d.max > 0 and (t.frac or 0) > 0 and not d.pouring
    verbs[#verbs + 1] = { id = "pour", label = txt("Fluid_Transfer", "Pour"):upper(), primary = true, enabled = pourOK,
        run = function(p, tt) def.pour(p, tt) end }
    verbs[#verbs + 1] = { id = "switch", label = txt("Fluid_Swap", "Switch"):upper(),
        enabled = (t.from ~= nil or t.into ~= nil) and not d.pouring,
        run = function(p, tt) setSides(tt, tt.into, tt.from) end }
    local emptyOK = ffc ~= nil and not ffc:isEmpty() and ffc:canPlayerEmpty() and not t.from:isResource() and not d.pouring
    local emptyQ = nil
    if emptyOK then
        emptyQ = "Pour " .. L(ffc:getAmount()) .. " of " .. string.lower(d.fluid or "liquid") .. " out on the ground?"
    end
    verbs[#verbs + 1] = { id = "empty", label = txt("Fluid_Empty", "Empty"):upper(), enabled = emptyOK, danger = true,
        confirm = emptyQ,
        run = function(p, tt)
            local c = tt.from
            if not c then return end
            local fc = c:getFluidContainer()
            if c:isItem() then ISFluidContainerMenu.emptyFluidContainer(p, fc)
            else ISWorldObjectContextMenu.onFluidEmpty(p:getPlayerNum(), fc) end
        end }
    if d.reason then needs[#needs + 1] = d.reason end
    t.verbs, t.needs = verbs, needs
end

-- Queue vanilla's pour: items come to the main inventory first, a world
-- container is walked to, then ISFluidTransferAction moves the amount.
function def.pour(p, t)
    local d = t.d
    if not (d and t.from and t.into and d.can) then return end
    local amount = FluidUtil.roundTransfer(d.max * (t.frac or 0))
    if amount <= 0 then return end
    for _, c in ipairs({ t.from, t.into }) do
        local o = c:getOwner()
        if o and instanceof(o, "InventoryItem") then ISInventoryPaneContextMenu.transferIfNeeded(p, o) end
    end
    local iso = (t.from:isIsoPanel() and t.from) or (t.into:isIsoPanel() and t.into) or nil
    if iso and not ISFluidUtil.doWalkTo(p, iso) then return end
    local a, b = t.from:copy(), t.into:copy()
    local act = ISFluidTransferAction:new(p, a, a:getFluidObject(), b, b:getFluidObject(), amount)
    ISTimedActionQueue.add(act)
    t.action = act
    t.pourAmount = amount
    t._refreshT = OC.REFRESH
end

function def.title(t) return (t.d and (t.d.fromName or t.d.intoName)) or txt("Fluid_Transfer_Fluids", "Liquid") end
function def.icon(t) return t.d and t.d.icon or nil end
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not (d and t.from) then return nil end
    if d.tainted then return string.upper(txt("Tooltip_tainted", "Tainted")), T.danger end
    if not d.fluid then return "EMPTY", T.textDim end
    return string.upper(d.fluid), T.textDim, d.fluidColor
end

-- An empty POUR INTO lands the controller on the first container that takes it.
function def.openFocus(t)
    local d = t.d
    if not d or t.into then return nil end
    for _, r in ipairs(d.rows or {}) do
        if r.canInto then return "fl:into:" .. r.key end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
local function col(c) return c.r, c.g, c.b end

local function dashed(card, x, y, w, h, c)
    local T = ZeD.T
    local seg, one = T.px(4), T.px(1)
    local sx = x
    while sx < x + w do
        local l = math.min(seg, x + w - sx)
        card:drawRect(sx, y, l, one, c.a or 1, col(c))
        card:drawRect(sx, y + h - one, l, one, c.a or 1, col(c))
        sx = sx + seg * 2
    end
    local sy = y
    while sy < y + h do
        local l = math.min(seg, y + h - sy)
        card:drawRect(x, sy, one, l, c.a or 1, col(c))
        card:drawRect(x + w - one, sy, one, l, c.a or 1, col(c))
        sy = sy + seg * 2
    end
end

-- horizontal hatching inside a band (what leaves / what arrives)
local function hatch(card, x, y, w, h, c, a)
    local T = ZeD.T
    local step, one = T.px(3), T.px(1)
    local yy = y + one
    while yy < y + h do
        card:drawRect(x, yy, w, one, a, col(c))
        yy = yy + step
    end
end

-- A vertical tank: layers bottom-up {amt, colour}; after = litres when the
-- pour is done (nil: no pour); incoming = {amt, colour} landing on top.
local function drawTank(card, x, y, w, h, cap, layers, after, incoming)
    local T = ZeD.T
    local s1 = T.surf1
    card:drawRect(x, y, w, h, 1, col(s1))
    cap = (cap and cap > 0) and cap or 1
    local function ph(l) return math.floor(h * math.max(0, math.min(cap, l)) / cap + 0.5) end
    local fill, total = 0, 0
    for _, ly in ipairs(layers) do
        local lh = math.min(ph(ly[1]), h - fill)
        if lh > 0 then card:drawRect(x, y + h - fill - lh, w, lh, 1, col(ly[2])) end
        fill = fill + lh
        total = total + ly[1]
    end
    if after and after < total - 0.0001 then
        -- the part that leaves: light hatching between the after line and the top of the fill
        local a = ph(after)
        hatch(card, x, y + h - fill, w, fill - a, { r = 1, g = 1, b = 1 }, 0.28)
    end
    if incoming and incoming[1] > 0 then
        local ih = math.min(ph(incoming[1]), h - fill)
        if ih > 0 then
            card:drawRect(x, y + h - fill - ih, w, ih, 0.55, col(incoming[2]))
            hatch(card, x, y + h - fill - ih, w, ih, { r = 0, g = 0, b = 0 }, 0.35)
        end
    end
    local bs = T.borderS
    for i, f in ipairs({ 0.25, 0.5, 0.75 }) do
        local tw = (i == 2) and T.px(14) or T.px(8)
        card:drawRect(x + w - tw, y + h - math.floor(h * f), tw, T.px(1), bs.a or 1, col(bs))
    end
    if after then
        local ay = y + h - ph(after)
        local tc = T.text
        card:drawRect(x - T.px(1), math.max(y, ay - T.px(1)), w + T.px(2), T.px(2), tc.a or 1, col(tc))
    end
    card:drawRectBorder(x, y, w, h, bs.a or 1, col(bs))
end

local function layersOf(liquids)
    local out = {}
    for _, l in ipairs(liquids) do out[#out + 1] = { l.amt, l.color or ZeD.T.info } end
    return out
end

-- One vessel box; returns its height.
local function drawVessel(card, x, y, w, label, name, fc, layers, after, incoming, hint)
    local T, tm = ZeD.T, ZeD.TM
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local tw, th = T.px(TANK_W), T.px(TANK_H)
    local h = T.px(6) + tm:getFontHeight(f1) + T.px(5) + th + T.px(5) + tm:getFontHeight(f2) + T.px(2) + tm:getFontHeight(f3) + T.px(7)
    if not fc then
        dashed(card, x, y, w, h, T.border)
    else
        local s2 = T.surf2
        card:drawRect(x, y, w, h, s2.a or 1, col(s2))
        card:drawRectBorder(x, y, w, h, T.border.a or 1, col(T.border))
    end
    local ac = T.accent
    local lw = tm:MeasureStringX(f1, label)
    local cy = y + T.px(6)
    card:drawText(label, x + math.floor((w - lw) / 2), cy, ac.r, ac.g, ac.b, 1, f1)
    cy = cy + tm:getFontHeight(f1) + T.px(5)
    if not fc then
        UI.para(card, x + T.px(12), cy + math.floor(th / 2) - tm:getFontHeight(f1), w - T.px(24), hint or "", T.textDim, f1)
        return h
    end
    if fc:isHiddenAmount() then layers, after, incoming = {}, nil, nil end   -- vanilla hides the level
    drawTank(card, x + math.floor((w - tw) / 2), cy, tw, th, fc:getCapacity(), layers, after, incoming)
    cy = cy + th + T.px(5)
    local n = ZeD.CraftingCore.truncText(name or "", f2, w - T.px(12))
    local nw = tm:MeasureStringX(f2, n)
    card:drawText(n, x + math.floor((w - nw) / 2), cy, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    cy = cy + tm:getFontHeight(f2) + T.px(2)
    local amt = fc:isHiddenAmount() and txt("Fluid_Unknown", "Unknown"):upper() or (L(fc:getAmount()) .. " / " .. L(fc:getCapacity()))
    local aw = tm:MeasureStringX(f3, amt)
    card:drawText(amt, x + math.floor((w - aw) / 2), cy, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f3)
    return h
end

-- The arrow between the tanks, the liquid and the amount.
local function drawFlow(card, x, y, w, h, d, amount, live)
    local T, tm = ZeD.T, ZeD.TM
    local f1 = T.fontF1
    local on = live and d.can
    local ac = on and T.accent or T.border
    local midY = y + math.floor(h / 2) - T.px(6)
    -- liquid name with its dot
    if d.fluid then
        local s = d.fluid
        local sw = tm:MeasureStringX(f1, s) + T.px(11)
        local sx = x + math.floor((w - sw) / 2)
        local sy = midY - T.px(16) - tm:getFontHeight(f1)
        ZeD.Atoms.drawStatusDot(card, sx, sy + math.floor((tm:getFontHeight(f1) - T.px(6)) / 2), d.fluidColor or T.info, T.px(6))
        card:drawText(s, sx + T.px(11), sy, T.text.r, T.text.g, T.text.b, T.text.a or 1, f1)
    end
    -- arrow: shaft + head
    local hw, hh = T.px(12), T.px(16)
    local ax0, ax1 = x + T.px(4), x + w - T.px(4)
    card:drawRect(ax0, midY - T.px(2), ax1 - hw - ax0, T.px(4), 1, col(ac))
    for k = 0, hw - 1 do
        local ch = math.floor(hh * (1 - k / hw))
        if ch > 0 then card:drawRect(ax1 - hw + k, midY - math.floor(ch / 2), 1, ch, 1, col(ac)) end
    end
    if amount then
        -- the amount, big, with L and the Max Pour under it
        local big = string.format("%.2f", amount)
        if amount >= 100 then big = string.format("%.0f", amount) elseif amount >= 10 then big = string.format("%.1f", amount) end
        local bpx = 28
        local by = midY + T.px(10)
        local bigW = ZeD.Text and ZeD.Text.width and ZeD.Text.width(ZeD.Font.sdf.head, big, ZeD.Text.zoomPx(bpx)) or tm:MeasureStringX(T.fontF4, big)
        local lW = tm:MeasureStringX(T.fontF3, "L")
        local bx = x + math.floor((w - bigW - T.px(3) - lW) / 2)
        UI.big(card, big, bx, by, bpx, live and T.text or T.textDim)
        card:drawText("L", bx + bigW + T.px(3), by + T.px(bpx) - tm:getFontHeight(T.fontF3), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF3)
        if not d.pouring then
            local sub = string.upper(txt("Fluid_Max_Transfer", "Max Pour")) .. " " .. L(d.max or 0)
            local sw = tm:MeasureStringX(T.fontF5, sub)
            card:drawText(sub, x + math.floor((w - sw) / 2), by + T.px(bpx) + T.px(4), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF5)
        end
    end
end

-- AMOUNT: label, slider, 1/4 1/2 ALL. Returns height.
local function drawAmount(card, x, y, w, t)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(22)
    local f1 = T.fontF1
    local ac = T.accent
    card:drawText("AMOUNT", x, y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local labels = { { "1/4", 0.25 }, { "1/2", 0.5 }, { "ALL", 1 } }
    local bx = x + w
    for i = #labels, 1, -1 do
        local lb = labels[i]
        local bw = math.max(T.px(30), UI.buttonW(lb[1]))
        bx = bx - bw
        local fid = "fl:step:" .. i
        local frac = lb[2]
        UI.button(card, bx, y + T.px(1), lb[1], { h = T.px(20), w = bw, primary = math.abs((t.frac or 0) - frac) < 0.001,
            focused = card._fid == fid })
        card:zone({ fid = fid, x = bx, y = y + T.px(1), w = bw, h = T.px(20), body = true,
            run = function() t.frac = frac; t._refreshT = OC.REFRESH end })
        bx = bx - T.px(4)
    end
    local sx0 = x + tm:MeasureStringX(f1, "AMOUNT") + T.px(14)
    local sx1 = bx - T.px(10)
    local sw = sx1 - sx0
    local trY = y + math.floor(h / 2) - T.px(3)
    local s1, bs = T.surf1, T.borderS
    card:drawRect(sx0, trY, sw, T.px(6), 1, col(s1))
    card:drawRect(sx0, trY, math.floor(sw * (t.frac or 0)), T.px(6), 1, col(ac))
    card:drawRectBorder(sx0, trY, sw, T.px(6), bs.a or 1, col(bs))
    for _, f in ipairs({ 0.25, 0.5, 0.75 }) do
        card:drawRect(sx0 + math.floor(sw * f), trY + T.px(8), T.px(1), T.px(4), bs.a or 1, col(bs))
    end
    local thW, thH = T.px(12), T.px(18)
    local thX = sx0 + math.floor(sw * (t.frac or 0)) - math.floor(thW / 2)
    local thY = y + math.floor((h - thH) / 2)
    local focused = card._fid == "fl:slider"
    if focused then card:drawRect(thX - T.px(3), thY - T.px(3), thW + T.px(6), thH + T.px(6), 0.55, col(ac)) end
    local tb = focused and T.accentBright or T.surf3
    card:drawRect(thX, thY, thW, thH, tb.a or 1, col(tb))
    card:drawRect(thX, thY, thW, T.px(1), T.surf4.a or 1, col(T.surf4))
    card:drawRect(thX, thY, T.px(1), thH, T.surf4.a or 1, col(T.surf4))
    card:drawRect(thX, thY + thH - T.px(1), thW, T.px(1), 1, 0, 0, 0)
    card:drawRect(thX + thW - T.px(1), thY, T.px(1), thH, 1, 0, 0, 0)
    card:zone({ fid = "fl:slider", x = sx0 - T.px(6), y = y, w = sw + T.px(12), h = h, body = true,
        drag = function(c, mx, my)
            local f = (mx - sx0) / math.max(1, sw)
            t.frac = math.max(0, math.min(1, f))
            t._refreshT = OC.REFRESH
        end,
        dpad = function(dir)
            if dir == "left" then t.frac = math.max(0, (t.frac or 0) - STEP)
            elseif dir == "right" then t.frac = math.min(1, (t.frac or 0) + STEP)
            else return false end
            t._refreshT = OC.REFRESH
            return true
        end })
    return h
end

-- POURING band with STOP
local function drawPouring(card, x, y, w, t)
    local T, tm = ZeD.T, ZeD.TM
    local ac = T.accent
    local h = T.px(32)
    card:drawRect(x, y, w, h, 0.10, col(ac))
    card:drawRectBorder(x, y, w, h, 1, col(ac))
    local f1, f3 = T.fontF1, T.fontF3
    local lbl = string.upper(txt("Fluid_Transferring", "Pouring"))
    card:drawText(lbl, x + T.px(8), y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local act = t.action
    local delta = jobDelta(act)
    local total = t.pourAmount or 0
    local v = L(total * delta):gsub(" L$", "") .. " of " .. L(total)
    local bw = UI.buttonW("STOP")
    local bx = x + w - T.px(6) - bw
    local fid = "fl:stop"
    UI.button(card, bx, y + math.floor((h - T.px(20)) / 2), "STOP", { h = T.px(20), focused = card._fid == fid })
    card:zone({ fid = fid, x = bx, y = y + math.floor((h - T.px(20)) / 2), w = bw, h = T.px(20), body = true,
        run = function() if act then pcall(function() act:forceStop() end) end; t._refreshT = OC.REFRESH end })
    local vw = tm:MeasureStringX(f3, v)
    local vx = bx - T.px(10) - vw
    card:drawText(v, vx, y + math.floor((h - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f3)
    local px0 = x + T.px(8) + tm:MeasureStringX(f1, lbl) + T.px(10)
    local pw = vx - T.px(10) - px0
    local py = y + math.floor((h - T.px(8)) / 2)
    card:drawRect(px0, py, pw, T.px(8), 1, col(T.surf1))
    card:drawRect(px0, py, math.floor(pw * delta), T.px(8), 1, col(ac))
    card:drawRectBorder(px0, py, pw, T.px(8), T.borderS.a or 1, col(T.borderS))
    return h
end

-- LIQUIDS rows
local function drawLiquids(card, x, y, w, d, fc)
    local T, tm = ZeD.T, ZeD.TM
    local y0 = y
    -- shares from the same reading as the amounts (the refresh), never the live total
    local total = 0
    for _, l in ipairs(d.fromLiquids) do total = total + l.amt end
    local cap = fc:getCapacity()
    local rh = T.px(24)
    for _, l in ipairs(d.fromLiquids) do
        local c = l.color or T.info
        local sw = T.px(12)
        card:drawRect(x + T.px(2), y + math.floor((rh - sw) / 2), sw, sw, 1, col(c))
        card:drawRectBorder(x + T.px(2), y + math.floor((rh - sw) / 2), sw, sw, T.borderS.a or 1, col(T.borderS))
        local f2, f3 = T.fontF2, T.fontF3
        local nx = x + T.px(2) + sw + T.px(8)
        card:drawText(l.name, nx, y + math.floor((rh - tm:getFontHeight(f2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
        if d.tainted and (l.tainted or l.poison) then
            UI.tag(card, nx + tm:MeasureStringX(f2, l.name) + T.px(6), y + math.floor((rh - T.px(16)) / 2), string.upper(txt("Tooltip_tainted", "Tainted")), T.danger)
        end
        local pctW, valW, barW = T.px(36), T.px(62), T.px(120)
        local rx = x + w - T.px(2)
        local pct = total > 0 and math.floor(100 * l.amt / total + 0.5) or 0
        ZeD.Atoms.drawTextRight(card, tostring(pct) .. "%", rx, y + math.floor((rh - tm:getFontHeight(f3)) / 2), f3, T.textDim)
        local lv = fc:isHiddenAmount() and "?" or L(l.amt)
        ZeD.Atoms.drawTextRight(card, lv, rx - pctW, y + math.floor((rh - tm:getFontHeight(f3)) / 2), f3, T.text)
        local bx = rx - pctW - valW - barW
        local by = y + math.floor((rh - T.px(8)) / 2)
        card:drawRect(bx, by, barW, T.px(8), 1, col(T.surf1))
        card:drawRect(bx, by, math.floor(barW * math.min(1, l.amt / math.max(0.0001, cap))), T.px(8), 1, col(c))
        card:drawRectBorder(bx, by, barW, T.px(8), T.borderS.a or 1, col(T.borderS))
        card:drawRect(x, y + rh - T.px(1), w, T.px(1), T.border.a or 1, col(T.border))
        y = y + rh
    end
    if d.poison then
        local f1, f3 = T.fontF1, T.fontF3
        local ac = T.accent
        card:drawText(string.upper(txt("Fluid_Poison", "Poison")), x + T.px(2), y + math.floor((rh - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
        local vw = tm:MeasureStringX(f3, d.poison)
        ZeD.Atoms.drawTextRight(card, d.poison, x + w - T.px(2), y + math.floor((rh - tm:getFontHeight(f3)) / 2), f3, T.text)
        ZeD.Atoms.drawStatusDot(card, x + w - T.px(2) - vw - T.px(11), y + math.floor((rh - T.px(6)) / 2), T.danger, T.px(6))
        card:drawRect(x, y + rh - T.px(1), w, T.px(1), T.border.a or 1, col(T.border))
        y = y + rh
    end
    return y - y0
end

-- YOUR CONTAINERS rows with FROM / INTO
local function drawRows(card, x, y, w, t, d)
    local T, tm = ZeD.T, ZeD.TM
    local y0 = y
    local rh = T.px(30)
    local f2, f5 = T.fontF2, T.fontF5
    local btnW = math.max(T.px(44), UI.buttonW("INTO"), UI.buttonW("FROM"))
    for _, r in ipairs(d.rows) do
        if r.isFrom or r.isInto then card:drawRect(x, y, w, rh, 0.07, col(T.accent)) end
        local isz = T.px(16)
        if r.tex then card:drawTextureScaledAspect(r.tex, x + T.px(2), y + math.floor((rh - isz) / 2), isz, isz, 1, 1, 1, 1) end
        -- buttons (right)
        local intoX = x + w - T.px(2) - btnW
        local fromX = intoX - T.px(4) - btnW
        local by = y + math.floor((rh - T.px(20)) / 2)
        local fFid, iFid = "fl:from:" .. r.key, "fl:into:" .. r.key
        UI.button(card, fromX, by, "FROM", { h = T.px(20), w = btnW, primary = r.isFrom, disabled = not (r.isFrom or r.canFrom),
            focused = card._fid == fFid })
        UI.button(card, intoX, by, "INTO", { h = T.px(20), w = btnW, primary = r.isInto, disabled = not (r.isInto or r.canInto),
            focused = card._fid == iFid })
        local rr = r
        card:zone({ fid = fFid, x = fromX, y = by, w = btnW, h = T.px(20), body = true,
            run = (r.canFrom) and function()
                -- picking the INTO container as FROM swaps the two sides
                if rr.isInto then setSides(t, rr.c, t.from) else setSides(t, rr.c, t.into) end
            end or nil })
        card:zone({ fid = iFid, x = intoX, y = by, w = btnW, h = T.px(20), body = true,
            run = (r.canInto) and function()
                if rr.isFrom then setSides(t, t.into, rr.c) else setSides(t, t.from, rr.c) end
            end or nil })
        -- tag
        local rx = fromX - T.px(8)
        if r.tag then
            local tc = (r.tagK == "dng" and T.danger) or (r.tagK == "warn" and T.warning) or T.textDim
            local tw = UI.tagW(r.tag)
            UI.tag(card, rx - tw, y + math.floor((rh - T.px(16)) / 2), r.tag, tc)
            rx = rx - tw - T.px(8)
        else
            rx = rx - UI.tagW("WON'T TAKE") - T.px(8)
        end
        -- mini gauge: bar + "amt / cap"
        local gw = T.px(104)
        local gx = rx - gw
        local gy = y + T.px(5)
        card:drawRect(gx, gy, gw, T.px(6), 1, col(T.surf1))
        if r.color and r.cap > 0 then card:drawRect(gx, gy, math.floor(gw * math.min(1, r.amt / r.cap)), T.px(6), 1, col(r.color)) end
        card:drawRectBorder(gx, gy, gw, T.px(6), T.borderS.a or 1, col(T.borderS))
        local at = r.hidden and txt("Fluid_Unknown", "Unknown"):upper() or (L(r.amt) .. " / " .. L(r.cap))
        ZeD.Atoms.drawTextRight(card, at, gx + gw, gy + T.px(8), f5, T.textDim)
        -- name + where
        local nx = x + T.px(2) + isz + T.px(8)
        local nmax = gx - T.px(8) - nx
        local ny = y + math.floor((rh - tm:getFontHeight(f2) - tm:getFontHeight(f5)) / 2)
        card:drawText(ZeD.CraftingCore.truncText(r.name, f2, nmax), nx, ny, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
        card:drawText(ZeD.CraftingCore.truncText(r.where or "", f5, nmax), nx, ny + tm:getFontHeight(f2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f5)
        local line = r.pin and T.borderS or T.border
        card:drawRect(x, y + rh - T.px(1), w, T.px(1), line.a or 1, col(line))
        y = y + rh
    end
    return y - y0
end

function def.body(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    if not d then return 0 end
    local y0 = y
    local gap = T.px(8)
    local ffc = t.from and t.from:getFluidContainer()
    local ifc = t.into and t.into:getFluidContainer()

    -- the pour amount and the levels after it
    local amount = nil
    if d.pouring then amount = t.pourAmount
    elseif d.can then amount = FluidUtil.roundTransfer(d.max * (t.frac or 0)) end
    local fromAfter, intoAfter, incoming = nil, nil, nil
    if ffc and ifc and amount and not d.pouring then
        fromAfter = ffc:getAmount() - amount
        intoAfter = ifc:getAmount() + amount
        incoming = { amount, d.fluidColor or T.info }
    elseif d.pouring and ffc and ifc then
        local delta = jobDelta(t.action)
        local left = (t.pourAmount or 0) * (1 - delta)
        fromAfter = math.max(0, ffc:getAmount() - left)
        intoAfter = ifc:getAmount() + left
        incoming = { left, d.fluidColor or T.info }
    end

    -- tanks + flow
    local vw = T.px(VESSEL_W)
    local hint = "Pick INTO on a container below"
    local hFrom = drawVessel(card, x, y, vw, string.upper(txt("Fluid_Source", "Pouring From")), d.fromName, ffc,
        layersOf(d.fromLiquids), fromAfter, nil, "Pick FROM on a container below")
    local hInto = drawVessel(card, x + w - vw, y, vw, string.upper(txt("Fluid_Target", "Pouring To")), d.intoName, ifc,
        layersOf(d.intoLiquids), intoAfter, incoming, hint)
    local th = math.max(hFrom, hInto)
    drawFlow(card, x + vw + T.px(10), y, w - vw * 2 - T.px(20), th, d, (ffc and ifc) and (amount or 0) or nil, ffc ~= nil and ifc ~= nil)
    y = y + th + gap

    -- amount / pouring / reason
    if d.pouring then
        y = y + drawPouring(card, x, y, w, t) + gap
    elseif ffc and ifc then
        if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + T.px(4) end
        if d.can and d.max > 0 then y = y + drawAmount(card, x, y, w, t) + gap end
    end

    -- liquids
    if ffc and #d.fromLiquids > 0 then
        y = y + UI.section(card, x, y, w, string.upper(txt("Fluid_Fluids", "Liquids")), string.upper(d.fromName or ""))
        y = y + drawLiquids(card, x, y, w, d, ffc) + gap
    end

    -- your containers
    y = y + UI.section(card, x, y, w, "YOUR CONTAINERS", tostring(#d.rows))
    y = y + drawRows(card, x, y, w, t, d)
    return y - y0
end

OC.register(def)
