-- ZeD-UI/42/media/lua/client/ZeD/StationGeneral.lua
-- ============================================================================
-- GENERAL STATION VIEW (client) — the Craft tab bound to a station ZeD has no
-- view of its own for.
-- Benches (CraftingTab), drying racks and any other plain craft machine
-- (StationMachine) and ovens (StationAppliance) have their views. Anything
-- else the game's ISEntityUI.OpenWindow would open (in 42.22 only mods add
-- these: a furnace or mashing logic, a tank, a store of items) lands here,
-- read from the components the entity has:
--   * a logic with a cycle (FurnaceLogic, MashingLogic, any component with
--     isRunning / canStart / start / stop / getProgress / getCurrentRecipe /
--     getPossibleRecipe): the recipe line, Start or Stop through the game's
--     ISEntityUI.GenericCraftStart (its walk and its ISGenericCraftStart
--     action), the cycle's progress;
--   * Resources: each resource with its role (the game's Input / Output, or
--     Holds), its items with Take (the game's ISItemSlotRemoveAction), its fluid
--     or energy as an amount and a strip;
--   * From your bags: what the station's item inputs accept (Resource
--     acceptsItem), each kind with Add (ISItemSlotAddAction).
-- Every call is asked by name under pcall (ST.call), so a mod's component that
-- lacks one leaves that part out.
-- ============================================================================

require "ZeD/Stations"

ZeD = ZeD or {}
ZeD.StationGeneral = ZeD.StationGeneral or {}
local SG = ZeD.StationGeneral
local ST = ZeD.Stations
local call = ST.call

local PAD, ROW_H, REFRESH = 10, 24, 20   -- body padding and row height (design px); frames between snapshots

local function texOf(item) return call(item, "getTex") or call(item, "getNormalTexture") end
local function nameOf(item) return call(item, "getDisplayName") or call(item, "getName") or "?" end

-- the role of a resource: "in", "out" or "any" (the game's ResourceIO); its kind: "item", "fluid", "energy"
local function ioOf(res) local s = tostring(call(res, "getIO") or "Any"); return (s == "Input" and "in") or (s == "Output" and "out") or "any" end
local function kindOf(res) local s = tostring(call(res, "getType") or "Item"); return (s == "Fluid" and "fluid") or (s == "Energy" and "energy") or "item" end
SG.ioOf, SG.kindOf = ioOf, kindOf

local function listOf(jl)
    local out = {}
    if jl and jl.size then for i = 0, jl:size() - 1 do out[#out + 1] = jl:get(i) end end
    return out
end

-- one decimal, a whole number shown whole
local function amount(v)
    v = tonumber(v) or 0
    if math.abs(v - math.floor(v + 0.5)) < 0.05 then return tostring(math.floor(v + 0.5)) end
    return string.format("%.1f", v)
end

--- Snapshot of the station: the logic's cycle, each resource, what the bags hold for the inputs.
local function gather(st, player)
    local d = { res = {}, bag = {} }
    local logic = st.comp
    if logic then
        d.logic = true
        d.running = call(logic, "isRunning") and true or false
        d.recipe = d.running and call(logic, "getCurrentRecipe") or call(logic, "getPossibleRecipe")
        d.progress = d.running and (tonumber(call(logic, "getProgress")) or 0) or 0
        d.canStart = (not d.running) and (call(logic, "canStart", player) and true or false) or false
    end
    local rc = ComponentType and call(st.obj, "getComponent", ComponentType.Resources)
    local inputs = {}
    for _, res in ipairs(listOf(rc and call(rc, "getResources"))) do
        local e = { res = res, io = ioOf(res), kind = kindOf(res), items = {} }
        if e.kind == "item" then
            local groups = {}
            for _, it in ipairs(listOf(call(res, "getStoredItems"))) do
                local ft = call(it, "getFullType") or "?"
                local g = groups[ft]
                if not g then
                    g = { type = ft, name = nameOf(it), tex = texOf(it), items = {} }
                    groups[ft] = g
                    e.items[#e.items + 1] = g
                end
                g.items[#g.items + 1] = it
            end
            e.n, e.cap = call(res, "getItemAmount") or 0, call(res, "getItemCapacity") or 0
            if e.io ~= "out" and (call(res, "getFreeItemCapacity") or 0) > 0 then inputs[#inputs + 1] = res end
        elseif e.kind == "fluid" then
            e.n, e.cap = call(res, "getFluidAmount") or 0, call(res, "getFluidCapacity") or 0
        else
            e.n, e.cap = call(res, "getEnergyAmount") or 0, call(res, "getEnergyCapacity") or 0
        end
        d.res[#d.res + 1] = e
    end
    -- what the bags hold that an input takes, by kind (the first input that takes it)
    if #inputs > 0 and ZeD.CraftingCore and ZeD.CraftingCore.buildContainers then
        local conts = ZeD.CraftingCore.buildContainers(player)
        local groups = {}
        for i = 0, conts:size() - 1 do
            for _, it in ipairs(listOf(call(conts:get(i), "getItems"))) do
                if not player:isEquipped(it) then
                    local ft = it:getFullType()
                    local g = groups[ft]
                    if g == nil then
                        g = false
                        for _, res in ipairs(inputs) do
                            if call(res, "acceptsItem", it) then g = { type = ft, name = nameOf(it), tex = texOf(it), items = {}, res = res }; break end
                        end
                        groups[ft] = g
                        if g then d.bag[#d.bag + 1] = g end
                    end
                    if g then g.items[#g.items + 1] = it end
                end
            end
        end
        table.sort(d.bag, function(a, b) return a.name < b.name end)
    end
    return d
end
SG.gather = gather

local function data(st, player)
    st._gdT = (st._gdT or REFRESH) + 1
    if st._gdT >= REFRESH or not st._gd then
        st._gdT = 0
        st._gd = gather(st, player)
    end
    return st._gd
end
local function dirty(st) st._gdT = REFRESH end

-- ----------------------------------------------------------------------------
-- ACTIONS (the game's own: each walks to the station first)
-- ----------------------------------------------------------------------------
local function walk(player, st) return ISEntityUI and ISEntityUI.WalkToEntity and ISEntityUI.WalkToEntity(player, st.obj) end

function SG.take(player, st, res, group)
    if not (res and group and #group.items > 0) or not walk(player, st) then return end
    for _, it in ipairs(group.items) do ISTimedActionQueue.add(ISItemSlotRemoveAction:new(player, st.obj, res, nil, it)) end
    dirty(st)
end

function SG.add(player, st, group)
    local res = group and group.res
    if not res or not walk(player, st) then return end
    local free = call(res, "getFreeItemCapacity") or 0
    for i, it in ipairs(group.items) do
        if i > free then break end
        ISTimedActionQueue.add(ISItemSlotAddAction:new(player, st.obj, it, res, nil))
    end
    dirty(st)
end

function SG.start(player, st)
    if not (st.comp and ISEntityUI and ISEntityUI.GenericCraftStart) then return end
    ISEntityUI.GenericCraftStart(player, st.obj, st.comp, function(p, e, c) return c:canStart(p) end, function(p, e, c) c:start(p) end)
    dirty(st)
end

function SG.stop(player, st)
    if not (st.comp and ISEntityUI and ISEntityUI.GenericCraftStart) then return end
    ISEntityUI.GenericCraftStart(player, st.obj, st.comp, function() return true end, function(p, e, c) c:stop(p) end)
    dirty(st)
end

-- ----------------------------------------------------------------------------
-- RENDER
-- ----------------------------------------------------------------------------
local function label(panel, text, x, y, h, color)
    local T = ZeD.T
    local c = color or T.textHead
    local s = ZeD.textCase(text)
    panel:drawText(s, x, y + math.floor((h - ZeD.TM:getFontHeight(T.fontF1)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF1)
    return ZeD.TM:MeasureStringX(T.fontF1, s)
end

local function roleWord(e)
    if e.io == "in" then return ZeD.tr("EC_CraftLogic_Inputs") end
    if e.io == "out" then return ZeD.tr("EC_CraftLogic_Outputs") end
    return ZeD.tr("UI_ZeD_Station_Holds")
end
local function kindWord(e)
    if e.kind == "fluid" then return getText("ContextMenu_Fluid") end
    if e.kind == "energy" then return getText("EC_Energy") end
    return nil
end

--- The body's rows in draw order (each { kind, e?, g? }). One list serves both
--- the height measure and the draw.
local function rows(d)
    local out = {}
    if d.logic then
        out[#out + 1] = { kind = "recipe" }
        out[#out + 1] = { kind = "cycle" }
    end
    for _, e in ipairs(d.res) do
        out[#out + 1] = { kind = "head", e = e }
        if e.kind == "item" then
            if #e.items == 0 then out[#out + 1] = { kind = "empty", e = e } end
            for _, g in ipairs(e.items) do out[#out + 1] = { kind = "stored", e = e, g = g } end
        else
            out[#out + 1] = { kind = "amount", e = e }
        end
    end
    local anyIn = false
    for _, e in ipairs(d.res) do if e.kind == "item" and e.io ~= "out" then anyIn = true end end
    if anyIn then
        out[#out + 1] = { kind = "bagsHead" }
        if #d.bag == 0 then out[#out + 1] = { kind = "nothingFits" } end
        for _, g in ipairs(d.bag) do out[#out + 1] = { kind = "bag", g = g } end
    end
    if #out == 0 then out[#out + 1] = { kind = "nothing" } end
    return out
end
SG.rows = rows

--- The view's whole frame: station header, the scrolling row body, the
--- dropdown overlay last. CraftingTab hands the tab over while a general
--- station is bound.
function SG.render(panel, win, x, y, w, h, state, st)
    local T, A, M, tm = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local player = win._playerObj
    state._lastZones = state.zones
    state.zones = {}
    state._gpFocusedId = ST.focusedId(win)
    local fid = state._gpFocusedId
    local zones = state.zones

    local headH = ST.renderViewHeader(panel, win, x, y, w, state, st)
    local d = data(st, player)
    local list = rows(d)
    local pad, rowH = T.px(PAD), T.px(ROW_H)
    local totalH = pad * 2 + #list * rowH

    local viewY, viewH = y + headH, h - headH
    local scroll = state.scroll
    local needsScroll = totalH > viewH
    scroll.visible = needsScroll
    local cw = needsScroll and (w - T.sp.scrollbarW) or w
    local off = 0
    if needsScroll then
        scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, viewY, viewH
        scroll:setBarSize(viewH / totalH)
        off = math.floor(scroll.scrollPos * (totalH - viewH))
    else
        scroll:setScrollPos(0)
    end
    ST.followFocus(state, scroll, fid, viewY, viewH, totalH)

    local mx, my = panel:getMouseX(), panel:getMouseY()
    if state.stDropdownOpen then mx, my = -1, -1 end
    local function hov(zx, zy, zw, zh) return mx >= zx and mx < zx + zw and my >= zy and my < zy + zh and my >= viewY end

    panel:setStencilRect(x, viewY, cw, viewH)
    local lx, rx = x + pad, x + cw - pad
    local iw = rx - lx
    local cy = viewY + pad - off
    local bh = math.min(T.buttonH - T.px(4), rowH)
    local f2, f1 = T.fontF2, T.fontF1
    local tc = T.text
    local function mid(font) return cy + math.floor((rowH - tm:getFontHeight(font)) / 2) end
    local function button(id, text, variant, enabled, z)
        local bw = math.max(T.px(56), M.buttonW(text))
        local by = cy + math.floor((rowH - bh) / 2)
        M.drawButton(panel, rx - bw, by, bw, bh, text, variant, false, nil,
            { disabled = not enabled, hover = enabled and hov(rx - bw, by, bw, bh), focus = (fid == id) or nil })
        z.fid, z.x, z.y, z.w, z.h, z.enabled = id, rx - bw, by, bw, bh, enabled
        zones[#zones + 1] = z
        return bw
    end
    local function itemLine(g, room)
        local isz = T.px(16)
        if g.tex then panel:drawTextureScaledAspect(g.tex, lx, cy + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local s = ZeD.CraftingCore.truncText(g.name .. "  x" .. tostring(#g.items), f2, room - isz - T.px(6))
        panel:drawText(s, lx + isz + T.px(6), mid(f2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    end

    for _, r in ipairs(list) do
        if r.kind == "recipe" then
            local lw = label(panel, ZeD.tr("UI_ZeD_Machine_Recipe"), lx, cy, rowH)
            local rname = d.recipe and (call(d.recipe, "getTranslationName") or call(d.recipe, "getName")) or getText("UI_None")
            local c = d.recipe and tc or T.textDim
            panel:drawText(ZeD.CraftingCore.truncText(rname, f2, iw - lw - T.px(8)), lx + lw + T.px(8), mid(f2), c.r, c.g, c.b, c.a or 1, f2)
        elseif r.kind == "cycle" then
            local text = ZeD.tr(d.running and "UI_ZeD_Machine_Stop" or "UI_ZeD_Machine_Start")
            local bw = math.max(T.px(70), M.buttonW(text))
            local by = cy + math.floor((rowH - bh) / 2)
            local enabled = d.running or d.canStart
            M.drawButton(panel, lx, by, bw, bh, text, d.running and "default" or "primary", false, nil,
                { disabled = not enabled, hover = enabled and hov(lx, by, bw, bh), focus = (fid == "craft:g:start") or nil })
            zones[#zones + 1] = { type = "gStart", fid = "craft:g:start", enabled = enabled, running = d.running, x = lx, y = by, w = bw, h = bh }
            local pct = d.running and (tostring(math.floor(math.max(0, math.min(1, d.progress)) * 100 + 0.5)) .. "%") or ""
            local ptw = tm:MeasureStringX(T.fontF3, pct)
            local px0 = lx + bw + T.px(8)
            local pbw = math.max(T.px(30), rx - px0 - (ptw > 0 and (ptw + T.px(8)) or 0))
            A.drawSmoothBar(panel, px0, cy + math.floor((rowH - T.fillBarH) / 2), pbw, d.running and d.progress or 0, false, T.accent, T.fillBarH)
            if ptw > 0 then A.drawTextRight(panel, pct, rx, mid(T.fontF3), T.fontF3, tc) end
        elseif r.kind == "head" then
            local e = r.e
            local lw = label(panel, roleWord(e), lx, cy, rowH)
            local kw = kindWord(e)
            if kw then lw = lw + T.px(8) + label(panel, kw, lx + lw + T.px(8), cy, rowH, T.textDim) end
            if e.kind == "item" and e.cap > 0 then label(panel, tostring(e.n) .. " / " .. tostring(e.cap), lx + lw + T.px(8), cy, rowH, T.textDim) end
            A.drawDividerH(panel, lx, cy + rowH - T.px(1), iw, false)
        elseif r.kind == "stored" then
            local bw = button("craft:g:take:" .. tostring(r.e.res) .. ":" .. r.g.type, getText("ContextMenu_Take"), "default", true,
                { type = "gTake", res = r.e.res, group = r.g })
            itemLine(r.g, iw - bw - T.px(8))
        elseif r.kind == "amount" then
            local e = r.e
            local s = ZeD.tr(e.kind == "fluid" and "UI_ZeD_Station_AmountL" or "UI_ZeD_Station_Amount", amount(e.n), amount(e.cap))
            local sw = tm:MeasureStringX(f2, s)
            panel:drawText(s, lx, mid(f2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            local f = (e.cap and e.cap > 0) and math.max(0, math.min(1, e.n / e.cap)) or 0
            A.drawSmoothBar(panel, lx + sw + T.px(10), cy + math.floor((rowH - T.fillBarH) / 2), math.max(T.px(30), iw - sw - T.px(10)), f, false, T.accent, T.fillBarH)
        elseif r.kind == "empty" then
            M.drawEmptyLine(panel, lx, mid(f2), iw, getText("ContextMenu_Empty"))
        elseif r.kind == "bagsHead" then
            label(panel, ZeD.tr("UI_ZeD_Machine_FromBags"), lx, cy, rowH)
            A.drawDividerH(panel, lx, cy + rowH - T.px(1), iw, false)
        elseif r.kind == "nothingFits" then
            M.drawEmptyLine(panel, lx, mid(f2), iw, ZeD.tr("UI_ZeD_Machine_NothingFitsAny"))
        elseif r.kind == "bag" then
            local bw = button("craft:g:add:" .. r.g.type, ZeD.tr("UI_ZeD_Machine_Add"), "default", true, { type = "gAdd", group = r.g })
            itemLine(r.g, iw - bw - T.px(8))
        elseif r.kind == "nothing" then
            M.drawEmptyLine(panel, lx, mid(f2), iw, getText("ContextMenu_Empty"))
        end
        cy = cy + rowH
    end

    panel:clearStencilRect()
    if needsScroll then scroll:draw(panel) end
    ST.drawDropdownFor(panel, state, player, fid, "craft")
end

-- ----------------------------------------------------------------------------
-- INPUT
-- ----------------------------------------------------------------------------
local function hit(z, x, y) return x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end

--- Run a hit zone's action: take, add, or start / stop the cycle.
local function activate(player, st, z)
    if z.type == "gTake" then SG.take(player, st, z.res, z.group)
    elseif z.type == "gAdd" then SG.add(player, st, z.group)
    elseif z.type == "gStart" then
        if z.running then SG.stop(player, st) elseif z.enabled then SG.start(player, st) end
    end
end
SG.activate = activate

--- A left click in the view: the header (select, open dropdown) first, then
--- the zones. Always handled — nothing falls through to the tab under it.
function SG.onClick(win, state, st, x, y)
    local player = win._playerObj
    if ST.viewHeaderClick(state, player, x, y) then return true end
    for _, z in ipairs(state.zones or {}) do
        if z.type ~= "stationDropdown" and hit(z, x, y) then
            activate(player, st, z)
            return true
        end
    end
    return true
end

function SG.onMouseWheel(win, state, st, del, x, y)
    if state.stDropdownOpen then return ST.dropdownWheel(state, del) end
    if state.scroll and state.scroll.visible then state.scroll:handleMouseWheel(del) end
    return true
end

--- The controller's elements for this frame: the station select, then every
--- enabled zone, each activating as a click would.
function SG.buildFocusables(win, state, st)
    if state.stDropdownOpen then return ST.dropdownFocusables(state, win._playerObj, "craft") end
    local out = {}
    local sel = ST.selectFocusable(state)
    if sel then out[#out + 1] = sel end
    for _, z in ipairs(state.zones or {}) do
        if z.fid and z.enabled ~= false then
            out[#out + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h, id = z.fid, craftKind = z.type, zone = z,
                onFocus = function(w, el) end,
                onActivate = function(w, el) activate(w._playerObj, st, el.zone) end,
            }
        end
    end
    ST.addLeaveCancel(out, win, "craft")
    return out
end

--- Rebuild focusables when the station's contents change shape.
function SG.focusKey(win, state, st)
    local d = st._gd
    if not d then return "g" end
    local n = 0
    for _, e in ipairs(d.res) do n = n + #e.items end
    return "g" .. tostring(n) .. "/" .. tostring(#d.bag) .. "/" .. tostring(d.running) .. "/" .. tostring(d.canStart)
        .. "/" .. tostring(state.scroll and state.scroll.scrollPos or 0)
end

print("[ZeD] StationGeneral: the general station view loaded")
return SG
