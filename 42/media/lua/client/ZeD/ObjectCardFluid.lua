-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardFluid.lua
-- ============================================================================
-- OBJECT CARD: FLUIDS (HOOK_MAP rows 8 and 9)
-- Client; one card kind for ZeD.ObjectCards (ObjectCards.lua draws the frame,
-- this def fills it).
-- Vanilla's "Transfer Liquid" and "Container Info" windows become one fluid
-- card in the World window's card drawer:
--   * From and Into side by side, each with its level and ten segments, what
--     leaves and what arrives hatched; a narrow card (the half card) stacks
--     From over Into (the director's call, fluid card side by side, Nov 26 2026);
--   * the amount as - / + around the litres, in quarters of vanilla's Max Pour
--     (the smaller of what the left holds and the room in the right, rounded
--     by FluidUtil.roundTransfer), starting at the most;
--   * a mixture or a tainted liquid on the From side: each liquid with its
--     share; the "Tainted" flag where vanilla's tooltip shows it (poison level
--     only in debug, as vanilla);
--   * Other containers: every liquid container you carry (and the world
--     container the card opened on, pinned) but the two in the pour, each
--     with From / Into and a tag for what a pour into it would do, from
--     vanilla's own refusal reasons;
--   * verbs Pour (vanilla's ISFluidTransferAction), Switch, Empty (the band
--     at the foot asks first, vanilla's empty action); while it pours, a
--     progress strip with Stop. The verbs show only when they make sense.
-- The card follows a world container within OC.LEASH tiles; a pour between
-- your own containers has no tile and no leash.
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

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
    return (owner and call(owner, "getTileName")) or ZeD.tr("UI_ZeD_Fluid_Container")
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

-- (shared with the loot card, ZeD_LootCard.lua, so a container's liquid reads the same on both: punch list 151)
ZeD.Fluid = ZeD.Fluid or {}
ZeD.Fluid.L, ZeD.Fluid.liquidsOf, ZeD.Fluid.taintedShown, ZeD.Fluid.fluidLabel = L, liquidsOf, taintedShown, fluidLabel

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
            -- (the tag is a translation key, shown through ZeD.tr below)
            [txt("Fluid_Reason_Target_Full", "Container is full.")] = { "UI_ZeD_Fluid_TagFull", "dim" },
            [txt("Fluid_Reason_Mixing_Locked", "Cannot mix these liquids.")] = { "UI_ZeD_Fluid_TagWontMix", "dng" },
            [txt("Fluid_Reason_Target_Filter", "Cannot pour this liquid into target container.")] = { "UI_ZeD_Fluid_TagWontTake", "dng" },
            [txt("Fluid_Reason_Target_Locked", "Cannot pour into target container.")] = { "UI_ZeD_Fluid_TagWontTake", "dng" },
        }
    end
    local r = reason and REASONS[reason]
    if r then return ZeD.tr(r[1]), r[2] end
    return nil, nil
end

-- The engine refuses any pour into a container you carry while your
-- inventory is over its limit, then reports its last reason ("Cannot mix
-- these liquids."). Name the real cause instead.
-- (an internal marker; the sentence the player reads is UI_ZeD_Fluid_TooFull)
local TOO_FULL = "ZeD:TooFull"
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

-- The whole chain the card queued for a pour or an empty (the item moves, the walk, the action itself) is kept on
-- the card (t.queued) and looked up in the game's queue, as the Vehicle tab's chainBusy does. The card asked only
-- after the pour action at its next refresh, so two presses in one frame queued two pours (QA FL4, Nov 26 2026).
local function gameQueue(p)
    local ok, q = pcall(function() return ISTimedActionQueue.getTimedActionQueue(p) end)
    if ok and q and type(q.queue) == "table" then return q end
    return nil
end
local function inQueue(q, a)
    for i = 1, #q.queue do if q.queue[i] == a then return true end end
    return false
end
local function chainBusy(t, p)
    local list = t and t.queued
    if not list then return false end
    local q = gameQueue(p)
    if q then
        for i = 1, #list do if inQueue(q, list[i]) then return true end end
    end
    t.queued, t.action = nil, nil
    return false
end

-- Runs fn, which queues the game's actions, and keeps what it added.
local function track(t, p, fn)
    local q = gameQueue(p)
    local before = {}
    if q then for i = 1, #q.queue do before[q.queue[i]] = true end end
    local ok, err = pcall(fn)
    if not ok then print("[ZeD] fluid card: queueing failed: " .. tostring(err)) end
    q = gameQueue(p)
    local list = {}
    if q then
        for i = 1, #q.queue do
            local a = q.queue[i]
            if not before[a] then list[#list + 1] = a end
        end
    end
    t.queued = (#list > 0) and list or nil
end

-- Stop: the game's own stop when the running action is the chain's (it ends that action and empties the queue, as
-- moving does), then what is left of the chain taken out unstarted. Stop called forceStop on the pour, whose Java
-- action is nil until the walk ends, so it threw, the walk went on and the pour ran (QA FL3, Nov 26 2026).
local function stopChain(t, p)
    local list = t.queued or {}
    local q = gameQueue(p)
    local head = q and q.queue[1]
    if head then
        for i = 1, #list do
            if list[i] == head then pcall(function() ISTimedActionQueue.clear(p) end); break end
        end
    end
    q = gameQueue(p)
    if q then
        for i = #list, 1, -1 do
            local a = list[i]
            if inQueue(q, a) then
                pcall(function() q:removeFromQueue(a) end)
                pcall(function() a:forceCancel() end)
            end
        end
    end
    t.queued, t.action = nil, nil
    t._refreshT = OC.REFRESH
end

-- halfOk: its body is laid out for the half card, so it gives way to it where the window is held in (OC4)
local def = { id = "fluid", halfOk = true }

--- arg = { container = ISFluidContainer, source = bool, info = bool }.
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

-- The pinned world container, found again on its square. A pour can swap the game's object under it (a rain
-- collector's object is rebuilt as its level changes), so the old one no longer exists in the world though the
-- collector stands where it stood; the card took that for "the object is gone" and closed right after a pour (QA
-- FL4 / FL8, Nov 26 2026). The same square's object with a fluid container takes its place, on both sides.
local function repin(t)
    local sq = t.sq
    if not sq then return false end
    local objs = call(sq, "getObjects")
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local fc = call(o, "getFluidContainer")
        if fc then
            local c = ISFluidContainer:new(fc)
            if ISFluidUtil.validateContainer(c) then
                local old = t.pinned
                t.pinned = c
                if t.from == old then t.from = c end
                if t.into == old then t.into = c end
                print("[ZeD] fluid card: the pinned container's object was replaced; found again on its square")
                return true
            end
        end
    end
    return false
end

function def.valid(t)
    if t.pinned and not ISFluidUtil.validateContainer(t.pinned) then
        if repin(t) then return true end
        print("[ZeD] fluid card: not valid: the pinned world container is gone (no fluid container on its square)")
        return false
    end
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

    -- busy with what the card queued (an empty, or a pour from its first step), and pouring
    local hadPour = t.action ~= nil
    d.busy = chainBusy(t, player)
    d.pouring = d.busy and t.action ~= nil
    -- the pour this card queued is over (Stop clears t.action first, so a stopped one is not): a card opened from
    -- another (the trough's Add water and Transfer) goes back to it, which reads the new level (QA TG7, Nov 26 2026)
    if hadPour and not d.busy then
        t._returnNow = true
        -- the next pour starts at the most again, as a new pair does (the director's call, fluid card side by side,
        -- Nov 26 2026)
        t.frac = 1
    end

    -- rows: the pinned world container, then what you carry
    local rows = {}
    if t.pinned then
        rows[1] = { c = t.pinned, key = "pin", pin = true,
            where = ZeD.tr("UI_ZeD_ObjCard_WhereNearby") }
        if t.sq then
            local n = math.floor(OC.squareDist(player, t.sq) + 0.5)
            rows[1].where = ZeD.tr(n == 1 and "UI_ZeD_Fluid_NearbyTile" or "UI_ZeD_Fluid_NearbyTiles", n)
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
                if fc:isEmpty() then r.tag = ZeD.tr("Fluid_Empty")
                else
                    local prim = ffc:getPrimaryFluid()
                    if prim and ffc:isPureFluid(prim) and fc:isPureFluid(prim) then r.tag = ZeD.tr("UI_ZeD_Fluid_TagSame")
                    else r.tag, r.tagK = ZeD.tr("UI_ZeD_Fluid_TagMixes"), "warn" end
                end
            else
                local why = reasonFor(ffc, fc, player)
                if why == TOO_FULL then r.tag, r.tagK = ZeD.tr("UI_ZeD_Fluid_TagTooHeavy"), "dng"
                else r.tag, r.tagK = tagForReason(why) end
                r.canInto = false
            end
        elseif not r.isFrom and fc:isEmpty() then
            r.tag = ZeD.tr("Fluid_Empty")
        end
        if d.busy then r.canFrom, r.canInto = false, false end
    end
    d.rows = rows

    -- the pour
    d.can = ffc ~= nil and ifc ~= nil and FluidContainer.CanTransfer(ffc, ifc)
    d.max = 0
    if d.can then
        d.max = FluidUtil.roundTransfer(math.min(ffc:getAmount(), ifc:getCapacity() - ifc:getAmount()))
    end
    -- (QA FL6, Nov 26 2026) a well hides its amount (its script's HiddenAmount; the game's panel writes Unknown
    -- for stored, capacity and free): the most a pour can move gives it away when the hidden side sets it, so
    -- then the arrow's amount, Max Pour and the progress read Unknown too
    d.fromHidden = ffc ~= nil and ffc:isHiddenAmount() == true
    d.intoHidden = ifc ~= nil and ifc:isHiddenAmount() == true
    d.maxHidden = false
    if ffc and ifc then
        local free = ifc:getCapacity() - ifc:getAmount()
        d.maxHidden = (d.fromHidden and ffc:getAmount() <= free) or (d.intoHidden and free <= ffc:getAmount())
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
    local verbs = {}
    local pourOK = d.can and d.max > 0 and (t.frac or 0) > 0 and not d.busy
    -- Pour waits for the two sides; when the engine refuses the pair, its own words say why
    -- (needsLine); while what the card queued runs the verbs stay, greyed, and the strip in the
    -- body has Stop (QA FL4, Nov 26 2026)
    local pourNeeds = "UI_ZeD_Fluid_NeedsFit"
    if d.busy then pourNeeds = "UI_ZeD_Fluid_NeedsIdle"
    elseif d.can and d.max <= 0 then pourNeeds = "UI_ZeD_Fluid_NeedsLiquid"
    elseif d.can then pourNeeds = "UI_ZeD_Fluid_NeedsAmount" end
    local idle = ZeD.tr("UI_ZeD_Fluid_NeedsIdle")
    verbs[#verbs + 1] = { id = "pour", label = txt("Fluid_Transfer", "Pour"), primary = true, enabled = pourOK,
        sensible = ffc ~= nil and ifc ~= nil,
        needs = ZeD.tr(pourNeeds), hint = ZeD.tr("UI_ZeD_Fluid_HintPour"),
        needsLine = (d.reason and not d.busy) and ((d.reason == TOO_FULL) and ZeD.tr("UI_ZeD_Fluid_TooFull") or d.reason) or nil,
        help = ZeD.tr("UI_ZeD_Fluid_HelpPour"),
        run = function(p, tt) def.pour(p, tt) end }
    verbs[#verbs + 1] = { id = "switch", label = txt("Fluid_Swap", "Switch"),
        enabled = not d.busy, sensible = (t.from ~= nil or t.into ~= nil), needs = idle,
        help = ZeD.tr("UI_ZeD_Fluid_HelpSwitch"),
        run = function(p, tt) if not chainBusy(tt, p) then setSides(tt, tt.into, tt.from) end end }
    local emptyCan = ffc ~= nil and not ffc:isEmpty() and ffc:canPlayerEmpty() and not t.from:isResource()
    local emptyQ = nil
    if emptyCan then
        -- the question names the container on the left: after Switch it can be the rain collector (QA FL2, Nov 26 2026)
        emptyQ = ZeD.tr("UI_ZeD_Fluid_QEmptyNamed", d.fromName or ZeD.tr("UI_ZeD_Fluid_Container"),
            d.fromHidden and txt("Fluid_Unknown", "Unknown") or L(ffc:getAmount()),   -- (QA FL6, Nov 26 2026)
            string.lower(d.fluid or ZeD.tr("UI_ZeD_Fluid_LiquidWord")))
    end
    verbs[#verbs + 1] = { id = "empty", label = txt("Fluid_Empty", "Empty"), enabled = emptyCan and not d.busy, sensible = emptyCan,
        danger = true, confirm = emptyQ, needs = idle, help = ZeD.tr("UI_ZeD_Fluid_HelpEmpty"),
        run = function(p, tt)
            local c = tt.from
            if not c or chainBusy(tt, p) then return end   -- (asked at the Yes: the card may have queued since the question)
            local fc = c:getFluidContainer()
            track(tt, p, function()
                if c:isItem() then ISFluidContainerMenu.emptyFluidContainer(p, fc)
                else ISWorldObjectContextMenu.onFluidEmpty(p:getPlayerNum(), fc) end
            end)
            tt._refreshT = OC.REFRESH
        end }
    t.verbs = verbs
end

-- Queue vanilla's pour: items come to the main inventory first, a world
-- container is walked to, then ISFluidTransferAction moves the amount.
-- The whole chain is kept (t.queued) for the busy gate and for Stop; the gate is asked here, live, as the
-- refresh's d.busy is up to a refresh old (QA FL3, FL4, Nov 26 2026).
function def.pour(p, t)
    local d = t.d
    if chainBusy(t, p) then return end
    if not (d and t.from and t.into and d.can) then return end
    local amount = FluidUtil.roundTransfer(d.max * (t.frac or 0))
    if amount <= 0 then return end
    local act = nil
    track(t, p, function()
        for _, c in ipairs({ t.from, t.into }) do
            local o = c:getOwner()
            if o and instanceof(o, "InventoryItem") then ISInventoryPaneContextMenu.transferIfNeeded(p, o) end
        end
        local iso = (t.from:isIsoPanel() and t.from) or (t.into:isIsoPanel() and t.into) or nil
        if iso and not ISFluidUtil.doWalkTo(p, iso) then return end
        local a, b = t.from:copy(), t.into:copy()
        act = ISFluidTransferAction:new(p, a, a:getFluidObject(), b, b:getFluidObject(), amount)
        ISTimedActionQueue.add(act)
    end)
    if not act then t._refreshT = OC.REFRESH; return end
    t.action = act
    t.pourAmount = amount
    t._refreshT = OC.REFRESH
end

--- The strip's Stop: the whole chain the card queued (the walk and the pour).
function def.stop(p, t) stopChain(t, p) end

function def.title(t) return (t.d and (t.d.fromName or t.d.intoName)) or txt("Fluid_Transfer_Fluids", "Liquid") end
function def.icon(t) return t.d and t.d.icon or nil end
--- The state tag: its words, the colour of its square mark (none for a plain tag), and a
--- mark colour of its own (the liquid's colour).
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not (d and t.from) then return nil end
    if d.tainted then return txt("Tooltip_tainted", "Tainted"), T.danger end
    if not d.fluid then return ZeD.tr("Fluid_Empty"), T.textDim end
    return d.fluid, T.textDim, d.fluidColor
end

--- An empty POUR INTO lands the controller on the first container that takes it.
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
-- From and Into side by side over the amount, then the other containers. A card narrower than this
-- stacks From over Into (the half card, 220). (the director's call, fluid card side by side, Nov 26 2026)
-- ---------------------------------------------------------------------------
local SIDE_BY_SIDE_W = 360   -- design units of body width: below it the two sides stack
local COL_GAP = 16           -- design units between the From and Into columns

local function col(c) return c.r, c.g, c.b end

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

-- The amount in quarters of the most a pour can move: 0 (nothing) to 4 (all). The - / + step it, and the
-- quarters replace the slider, so a press always lands on a step the words can name.
-- (the director's call, fluid card side by side, Nov 26 2026)
local function quarter(t) return math.max(0, math.min(4, math.floor((t.frac or 0) * 4 + 0.5))) end
local function stepAmount(t, by)
    local q = math.max(0, math.min(4, quarter(t) + by))
    t.frac = q / 4
    t._refreshT = OC.REFRESH
end

-- What one side shows: its row when it has one (the same reading as the list), else read off the container.
local function sideOf(d, c, isFrom)
    if not c then return nil end
    for _, r in ipairs(d.rows or {}) do
        if (isFrom and r.isFrom) or ((not isFrom) and r.isInto) then return r end
    end
    local fc = c:getFluidContainer()
    return { c = c, fc = fc, name = nameOf(c), amt = fc:getAmount(), cap = fc:getCapacity(), hidden = fc:isHiddenAmount(),
        color = (not fc:isEmpty()) and rgb(fc:getColor()) or nil }
end

-- One side's column: "From" and its level on the first line, the name (and where a world container stands) on
-- the second, its ten segments under them; what leaves hatched on From, what arrives on Into. No side picked
-- yet: the label and the hint. Returns the column's height.
local function drawSide(card, x, y, w, label, s, after, hint, isFrom, inColor)
    local T, tm = ZeD.T, ZeD.TM
    local A = ZeD.Atoms
    local f1, f2, f3, f5 = T.fontF1, T.fontF2, T.fontF3, T.fontF5
    local ac = T.accent
    local l1 = math.max(tm:getFontHeight(f1), tm:getFontHeight(f3))
    label = A.textCase(label)
    card:drawText(label, x, y + math.floor((l1 - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local cy = y + l1 + T.px(3)
    if not s then
        ZeD.Molecules.drawEmptyLine(card, x, cy, w, hint or "")
        return l1 + T.px(3) + tm:getFontHeight(f2)
    end
    local at = s.hidden and txt("Fluid_Unknown", "Unknown") or (L(s.amt) .. " / " .. L(s.cap))   -- (QA FL6, Nov 26 2026)
    local room = w - tm:MeasureStringX(f1, label) - T.px(8)
    A.drawTextRight(card, ZeD.CraftingCore.truncText(at, f3, room), x + w, y + math.floor((l1 - tm:getFontHeight(f3)) / 2), f3, T.text)
    -- (a world container's where keeps its room beside the name, which gives way first down to two fifths)
    local nmax = w
    if s.pin and s.where then nmax = math.max(math.floor(w * 0.4), w - tm:MeasureStringX(f5, s.where) - T.px(8)) end
    local n = ZeD.CraftingCore.truncText(s.name or "", f2, nmax)
    card:drawText(n, x, cy, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    if s.pin and s.where then
        local wx = x + tm:MeasureStringX(f2, n) + T.px(8)
        local wroom = x + w - wx
        if wroom > T.px(24) then
            card:drawText(ZeD.CraftingCore.truncText(s.where, f5, wroom), wx, cy + tm:getFontHeight(f2) - tm:getFontHeight(f5),
                T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f5)
        end
    end
    cy = cy + tm:getFontHeight(f2) + T.px(3)
    local sh = A.fillBarCompactH()
    local cap = (s.cap and s.cap > 0) and s.cap or 1
    local c = s.color or inColor or T.info
    local lit = s.hidden and 0 or A.fillSegsLit(math.min(1, s.amt / cap))   -- (no lit segments when hidden: QA FL6)
    if A.drawSegFill(card, x, cy, w, sh, 10, lit, c) then ZeD.Help.set(card, at) end
    if after and not s.hidden then
        local k = A.fillSegsLit(math.max(0, math.min(1, after / cap)))
        local function cellX(i) return x + math.floor(w * i / 10) end
        if isFrom and k < lit then
            hatch(card, cellX(k), cy, cellX(lit) - cellX(k), sh, { r = 1, g = 1, b = 1 }, 0.28)
        elseif (not isFrom) and k > lit then
            card:drawRect(cellX(lit), cy, cellX(k) - cellX(lit), sh, 0.55, col(c))
            hatch(card, cellX(lit), cy, cellX(k) - cellX(lit), sh, { r = 0, g = 0, b = 0 }, 0.35)
        end
    end
    return cy + sh - y
end

-- Amount: the label, - , the litres in a box, + ; at the full card the quarter's name at the right
-- ("1/2", "All"). The D-pad's left and right on either key step it too. Returns the height.
local function drawAmount(card, x, y, w, t, wide)
    local T, tm = ZeD.T, ZeD.TM
    local A = ZeD.Atoms
    local d = t.d
    local h = math.max(T.px(24), T.buttonH)
    local f1, f3 = T.fontF1, T.fontF3
    local ac = T.accent
    local off = d.busy or not (d.can and d.max > 0)
    local q = quarter(t)
    local lbl = A.textCase(getText("Fluid_Amount"))
    card:drawText(lbl, x, y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, off and 0.5 or 1, f1)
    local names = { "0", "1/4", "1/2", "3/4", getText("Fluid_All") }
    local qs = names[q + 1]
    local bh = T.buttonH - T.px(4)
    local bw = bh
    local gap = T.px(6)
    local sx = x + tm:MeasureStringX(f1, lbl) + T.px(10)
    local v = "--"
    if not off then v = d.maxHidden and txt("Fluid_Unknown", "Unknown") or L(FluidUtil.roundTransfer(d.max * q / 4)) end   -- (QA FL6)
    local qsW = wide and (tm:MeasureStringX(f3, qs) + T.px(8)) or 0
    local vbW = math.max(T.px(72), tm:MeasureStringX(f3, v) + T.px(16))
    vbW = math.max(T.px(40), math.min(vbW, x + w - qsW - sx - 2 * bw - 2 * gap))
    local by = y + math.floor((h - bh) / 2)
    local function key(fid, kx, word, delta, help, can)
        local hov = card._hoverFid == fid
        UI.button(card, kx, by, word, { w = bw, h = bh, disabled = off or not can, hover = hov, focus = card:focusOf(fid) })
        card:zone({ fid = fid, x = kx, y = by, w = bw, h = bh, body = true, help = help,
            run = (not off and can) and function() stepAmount(t, delta) end or nil,
            -- (the pad's left and right step the amount on either key; with nothing to pour they move on)
            dpad = function(dir)
                if off then return false end
                if dir == "left" then stepAmount(t, -1) elseif dir == "right" then stepAmount(t, 1) else return false end
                return true
            end })
    end
    key("fl:amt:less", sx, "-", -1, ZeD.tr("UI_ZeD_Fluid_HelpLess"), q > 0)
    local vx = sx + bw + gap
    UI.fill(card, vx, by, vbW, bh, "surf1")
    A.frame(card, vx, by, vbW, bh, T.borderS)
    A.drawTextRight(card, ZeD.CraftingCore.truncText(v, f3, vbW - T.px(8)), vx + vbW - T.px(6), by + math.floor((bh - tm:getFontHeight(f3)) / 2), f3,
        off and T.textDim or T.text)
    key("fl:amt:more", vx + vbW + gap, "+", 1, ZeD.tr("UI_ZeD_Fluid_HelpMore"), q < 4)
    if wide and not off then
        A.drawTextRight(card, qs, x + w, y + math.floor((h - tm:getFontHeight(f3)) / 2), f3, T.textDim)
    end
    return h
end

-- The pour under way: Pouring, its strip, "x of y" and Stop
local function drawPouring(card, x, y, w, t, player)
    local T, tm = ZeD.T, ZeD.TM
    local A = ZeD.Atoms
    local ac = T.accent
    local h = math.max(T.px(32), T.buttonH + T.px(8))
    UI.fill(card, x, y, w, h, "surf2")
    A.frame(card, x, y, w, h, T.borderS)
    local f1, f3 = T.fontF1, T.fontF3
    local lbl = A.textCase(txt("Fluid_Transferring", "Pouring"))
    card:drawText(lbl, x + T.px(8), y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local act = t.action
    local delta = jobDelta(act)
    local total = t.pourAmount or 0
    local done = L(total * delta):gsub(" L$", "")
    local v = ZeD.tr("UI_ZeD_Fluid_PourProgress", done, L(total))
    if t.d and t.d.maxHidden then v = txt("Fluid_Unknown", "Unknown") end   -- (QA FL6, Nov 26 2026)
    local stop = getText("IGUI_media_stop")
    local bw = UI.buttonW(stop)
    local bh = T.buttonH - T.px(4)
    local bx = x + w - T.px(6) - bw
    local fid = "fl:stop"
    UI.button(card, bx, y + math.floor((h - bh) / 2), stop, { w = bw, h = bh, fid = fid, body = true, focus = card:focusOf(fid),
        help = ZeD.tr("UI_ZeD_Fluid_HelpStop"),
        run = function() def.stop(player, t) end })
    -- (the half card: the litres only while they fit beside the label and Stop)
    local vw = tm:MeasureStringX(f3, v)
    local lx1 = x + T.px(8) + tm:MeasureStringX(f1, lbl) + T.px(10)
    local vx = bx - T.px(10) - vw
    if vx >= lx1 then
        card:drawText(v, vx, y + math.floor((h - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f3)
    else
        vx = bx
    end
    local pw = vx - T.px(10) - lx1
    local ph = A.fillBarCompactH()
    if pw > T.px(20) then A.drawSmoothBar(card, lx1, y + math.floor((h - ph) / 2), pw, delta, false, ac, ph) end   -- (the pour's progress: smooth)
    return h
end

-- A mixture or a tainted liquid on the From side: each liquid with its swatch and share, under the two sides.
-- One liquid alone is named in the title's tag already, so it gets no list. (the director's call, fluid card side
-- by side, Nov 26 2026)
local function drawLiquids(card, x, y, w, d, fc)
    local T, tm = ZeD.T, ZeD.TM
    local y0 = y
    -- shares from the same reading as the amounts (the refresh), never the live total
    local total = 0
    for _, l in ipairs(d.fromLiquids) do total = total + l.amt end
    local rh = T.px(20)
    local f2, f3 = T.fontF2, T.fontF3
    local pctW = T.px(36)
    -- (QA FL6, Nov 26 2026) hidden: no share and no amount, only the liquid's name
    local hidden = fc:isHiddenAmount()
    for _, l in ipairs(d.fromLiquids) do
        local c = l.color or T.info
        local sw = T.px(10)
        card:drawRect(x + T.px(2), y + math.floor((rh - sw) / 2), sw, sw, 1, col(c))
        card:drawRectBorder(x + T.px(2), y + math.floor((rh - sw) / 2), sw, sw, T.borderS.a or 1, col(T.borderS))
        local nx = x + T.px(2) + sw + T.px(8)
        local tagged = d.tainted and (l.tainted or l.poison)
        local tagTxt = txt("Tooltip_tainted", "Tainted")
        local tagW = tagged and (UI.tagW(tagTxt, true) + T.px(6)) or 0
        local name = ZeD.CraftingCore.truncText(l.name, f2, x + w - pctW - tagW - nx)
        card:drawText(name, nx, y + math.floor((rh - tm:getFontHeight(f2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
        if tagged then
            UI.tag(card, nx + tm:MeasureStringX(f2, name) + T.px(6), y + math.floor((rh - T.px(16)) / 2), tagTxt, T.danger)
        end
        local pct = total > 0 and math.floor(100 * l.amt / total + 0.5) or 0
        ZeD.Atoms.drawTextRight(card, hidden and "?" or (tostring(pct) .. "%"), x + w - T.px(2), y + math.floor((rh - tm:getFontHeight(f3)) / 2), f3, T.text)
        y = y + rh
    end
    if d.poison then
        local f1 = T.fontF1
        local ac = T.accent
        card:drawText(txt("Fluid_Poison", "Poison"), x + T.px(2), y + math.floor((rh - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
        local vw = tm:MeasureStringX(f3, d.poison)
        ZeD.Atoms.drawTextRight(card, d.poison, x + w - T.px(2), y + math.floor((rh - tm:getFontHeight(f3)) / 2), f3, T.text)
        ZeD.Atoms.drawStatusDot(card, x + w - T.px(2) - vw - T.px(10), y + math.floor((rh - T.px(6)) / 2), T.danger, T.px(6))
        y = y + rh
    end
    return y - y0
end

-- The other containers: rows with From / Into. The two in the pour stand in the columns above and leave the list,
-- so no level shows twice (the director's call, fluid card side by side, Nov 26 2026). A narrow card puts the
-- level and the keys on a second line under the name.
local function drawRows(card, x, y, w, t, d, wide)
    local T, tm = ZeD.T, ZeD.TM
    local A = ZeD.Atoms
    local y0 = y
    local f2, f5 = T.fontF2, T.fontF5
    local bh = T.buttonH - T.px(4)
    local rh = wide and math.max(T.px(30), T.buttonH) or (T.px(4) + math.max(tm:getFontHeight(f2), T.px(16)) + T.px(3) + bh + T.px(4))
    local fromTxt, intoTxt = ZeD.tr("UI_ZeD_Fluid_From"), ZeD.tr("UI_ZeD_Fluid_Into")
    local btnW = math.max(UI.buttonW(intoTxt), UI.buttonW(fromTxt))
    for _, r in ipairs(d.rows) do
        if not (r.isFrom or r.isInto) then
            local isz = T.px(16)
            local line1 = wide and rh or (T.px(4) + math.max(tm:getFontHeight(f2), isz))
            if r.tex then card:drawTextureScaledAspect(r.tex, x + T.px(2), y + math.floor((line1 - isz) / 2) + (wide and 0 or T.px(2)), isz, isz, 1, 1, 1, 1) end
            -- buttons (right; a narrow card's on the second line)
            local intoX = x + w - T.px(2) - btnW
            local fromX = intoX - T.px(4) - btnW
            local by = wide and (y + math.floor((rh - bh) / 2)) or (y + line1 + T.px(3))
            local fFid, iFid = "fl:from:" .. r.key, "fl:into:" .. r.key
            local rr = r
            UI.button(card, fromX, by, fromTxt, { w = btnW, h = bh, disabled = not r.canFrom,
                fid = fFid, body = true, focus = card:focusOf(fFid), help = ZeD.tr("UI_ZeD_Fluid_HelpFromRow", r.name),
                run = (r.canFrom) and function() setSides(t, rr.c, t.into) end or nil })
            UI.button(card, intoX, by, intoTxt, { w = btnW, h = bh, disabled = not r.canInto,
                fid = iFid, body = true, focus = card:focusOf(iFid), help = ZeD.tr("UI_ZeD_Fluid_HelpIntoRow", r.name),
                run = (r.canInto) and function() setSides(t, t.from, rr.c) end or nil })
            -- tag: what a pour into it would do (the mark carries the colour)
            local tagX = wide and (fromX - T.px(8)) or (x + w - T.px(2))
            local tw = 0
            local ty = wide and (y + math.floor((rh - T.px(16)) / 2)) or (y + math.floor((line1 - T.px(16)) / 2) + T.px(2))
            if r.tag then
                local tc = (r.tagK == "dng" and T.danger) or (r.tagK == "warn" and T.warning) or nil
                tw = UI.tagW(r.tag, tc ~= nil)
                UI.tag(card, tagX - tw, ty, r.tag, tc)
            elseif wide then
                tw = UI.tagW(ZeD.tr("UI_ZeD_Fluid_TagWontTake"), true)
            end
            local at = r.hidden and txt("Fluid_Unknown", "Unknown") or (L(r.amt) .. " / " .. L(r.cap))
            local nx = x + T.px(2) + isz + T.px(8)
            if wide then
                -- mini gauge: strip + "amt / cap"
                local rx = tagX - tw - T.px(8)
                local gw = T.px(104)
                local gx = rx - gw
                local gh = A.fillBarCompactH()
                local gy = y + T.px(4)
                -- ten segments; the help line the words under it ("1.2 L / 4.0 L", "Unknown")
                if A.drawSegFill(card, gx, gy, gw, gh, 10,
                        (not r.hidden) and A.fillSegsLit((r.color and r.cap > 0) and math.min(1, r.amt / r.cap) or 0) or 0, r.color or T.info) then   -- (no lit segments when hidden: QA FL6, Nov 26 2026)
                    ZeD.Help.set(card, at)
                end
                A.drawTextRight(card, at, gx + gw, gy + gh + T.px(2), f5, T.textDim)
                -- name + where
                local nmax = gx - T.px(8) - nx
                local ny = y + math.floor((rh - tm:getFontHeight(f2) - tm:getFontHeight(f5)) / 2)
                card:drawText(ZeD.CraftingCore.truncText(r.name, f2, nmax), nx, ny, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
                card:drawText(ZeD.CraftingCore.truncText(r.where or "", f5, nmax), nx, ny + tm:getFontHeight(f2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f5)
            else
                -- the name beside its tag; the level under it, left of the keys
                local nmax = tagX - tw - T.px(6) - nx
                card:drawText(ZeD.CraftingCore.truncText(r.name, f2, nmax), nx, y + math.floor((line1 - tm:getFontHeight(f2)) / 2) + T.px(2),
                    T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
                card:drawText(ZeD.CraftingCore.truncText(at, f5, fromX - T.px(6) - nx), nx, by + math.floor((bh - tm:getFontHeight(f5)) / 2),
                    T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f5)
            end
            local line = r.pin and T.borderS or T.border
            card:drawRect(x, y + rh - T.px(1), w, T.px(1), line.a or 1, col(line))
            y = y + rh
        end
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
    local wide = w >= T.px(SIDE_BY_SIDE_W)

    -- the pour amount and the levels after it
    local fromAfter, intoAfter = nil, nil
    if ffc and ifc and d.pouring then
        local left = (t.pourAmount or 0) * (1 - jobDelta(t.action))
        fromAfter = math.max(0, ffc:getAmount() - left)
        intoAfter = ifc:getAmount() + left
    elseif ffc and ifc and d.can and not d.busy then
        local amount = FluidUtil.roundTransfer(d.max * (t.frac or 0))
        fromAfter = ffc:getAmount() - amount
        intoAfter = ifc:getAmount() + amount
    end

    -- From and Into: two columns, or From over Into on a narrow card
    local fromS, intoS = sideOf(d, t.from, true), sideOf(d, t.into, false)
    local cw = wide and math.floor((w - T.px(COL_GAP)) / 2) or w
    local hFrom = drawSide(card, x, y, cw, ZeD.tr("UI_ZeD_Fluid_From"), fromS, fromAfter, ZeD.tr("UI_ZeD_Fluid_HintFrom"), true, nil)
    if wide then
        local hInto = drawSide(card, x + w - cw, y, cw, ZeD.tr("UI_ZeD_Fluid_Into"), intoS, intoAfter, ZeD.tr("UI_ZeD_Fluid_HintInto"), false, d.fluidColor)
        y = y + math.max(hFrom, hInto) + gap
    else
        y = y + hFrom + T.px(6)
        y = y + drawSide(card, x, y, cw, ZeD.tr("UI_ZeD_Fluid_Into"), intoS, intoAfter, ZeD.tr("UI_ZeD_Fluid_HintInto"), false, d.fluidColor) + gap
    end

    -- a mixture or a tainted liquid: what the From side holds
    if ffc and (#d.fromLiquids > 1 or d.tainted or d.poison) then
        y = y + drawLiquids(card, x, y, w, d, ffc) + gap
    end

    -- amount / pouring
    if d.pouring then
        y = y + drawPouring(card, x, y, w, t, player) + gap
    elseif ffc and ifc then
        y = y + drawAmount(card, x, y, w, t, wide) + gap
    end

    -- the other containers
    local n = 0
    for _, r in ipairs(d.rows) do if not (r.isFrom or r.isInto) then n = n + 1 end end
    local head = (t.from or t.into) and ZeD.tr("UI_ZeD_Fluid_OtherContainers") or ZeD.tr("UI_ZeD_Fluid_YourContainers")
    y = y + UI.section(card, x, y, w, head, tostring(n))
    y = y + drawRows(card, x, y, w, t, d, wide)
    return y - y0
end

OC.register(def)
