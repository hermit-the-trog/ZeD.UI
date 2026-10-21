-- ZeD-UI/42/media/lua/client/ZeD/StationMachine.lua
-- ============================================================================
-- MACHINE VIEW — the Craft tab bound to a drying rack (HOOK_MAP row 1)
-- A drying rack is a machine, not a bench: items go into its input slots, a
-- START begins the drying cycle, finished items land in its output slots.
-- Vanilla shows this through ISCraftLogicPanel; ZeD draws it from scratch on
-- the same Java contract:
--   DryingCraftLogic : getInputResources / getOutputResources, isRunning,
--                      canStart / start / stop (wrapped in ISGenericCraftStart),
--                      getProgress(craftRecipeData), getCurrentRecipe,
--                      getPossibleRecipe, getFreeOutputSlotCount
--   CraftLogicUILogic: getItemsInProgress (craftRecipeData -> item -> count)
--   ResourceItem     : getStoredItems, getItemCapacity, acceptsItem
--   ISItemSlotAddAction / ISItemSlotRemoveAction move items in and out.
-- Layout: STATION select and band, then one scrolling body: the recipe line,
-- the input grid (each slot with its own progress), START / STOP with the
-- cycle's progress and time left, the output grid with TAKE ALL, and the
-- items in your bags the rack accepts, each with ADD.
-- ============================================================================

require "ZeD/Stations"

ZeD = ZeD or {}
ZeD.StationMachine = ZeD.StationMachine or {}
local SM = ZeD.StationMachine
local ST = ZeD.Stations
local call = ST.call

local COLS    = 10    -- slots per grid row
local CELL_H  = 38    -- design px
local GAP     = 4
local PAD     = 10
local ROW_H   = 24
local REFRESH = 20    -- frames between machine data refreshes

-- ----------------------------------------------------------------------------
-- DATA
-- ----------------------------------------------------------------------------
local function texOf(item)
    return call(item, "getTex") or call(item, "getNormalTexture")
end

local function nameOf(item)
    return call(item, "getDisplayName") or call(item, "getName") or "?"
end

local function containerLabel(c, player)
    if c == player:getInventory() then return ZeD.upper(getText("IGUI_InventoryTooltip")) end
    local it = call(c, "getContainingItem")
    local n = it and call(it, "getDisplayName")
    return n and ZeD.upper(n) or ZeD.upper(getText("IGUI_ItemCat_Bag"))
end

-- Game seconds as "ABOUT 1 DAY" / "ABOUT 5 HOURS" / "ABOUT 20 MINUTES" (a whole phrase per count).
local function aboutTime(sec)
    sec = math.max(0, sec or 0)
    if sec >= 86400 * 1.5 then return ZeD.tr("UI_ZeD_Machine_AboutDays", math.floor(sec / 86400 + 0.5)) end
    if sec >= 86400 * 0.75 then return ZeD.tr("UI_ZeD_Machine_AboutDayOne") end
    if sec >= 5400 then return ZeD.tr("UI_ZeD_Machine_AboutHours", math.floor(sec / 3600 + 0.5)) end
    if sec >= 3000 then return ZeD.tr("UI_ZeD_Machine_AboutHourOne") end
    local m = math.max(1, math.floor(sec / 60 + 0.5))
    return ZeD.tr(m == 1 and "UI_ZeD_Machine_AboutMinuteOne" or "UI_ZeD_Machine_AboutMinutes", m)
end
SM.aboutTime = aboutTime

local function durationText(sec)
    sec = math.max(0, sec or 0)
    if sec >= 86400 then
        local d = math.floor(sec / 86400 + 0.5)
        return d == 1 and ZeD.tr("UI_ZeD_Machine_DayEachOne") or ZeD.tr("UI_ZeD_Machine_DaysEach", d)
    end
    if sec >= 3600 then
        local h = math.floor(sec / 3600 + 0.5)
        return h == 1 and ZeD.tr("UI_ZeD_Machine_HourEachOne") or ZeD.tr("UI_ZeD_Machine_HoursEach", h)
    end
    return ZeD.tr("UI_ZeD_Machine_MinEach", math.max(1, math.floor(sec / 60 + 0.5)))
end

local function uiLogic(st, player)
    if st.uiLogic == nil then
        st.uiLogic = false
        if CraftLogicUILogic and CraftLogicUILogic.new then
            local ok, l = pcall(CraftLogicUILogic.new, player, st.obj, st.comp)
            if ok and l then st.uiLogic = l end
        end
    end
    return st.uiLogic or nil
end

-- Item types the rack's recipes take (cached on the station). The input slot
-- itself accepts anything, so this is what decides "fits".
local function inputTypes(st)
    if st.inTypes then return st.inTypes end
    local set = {}
    local list = st.comp and call(st.comp, "getRecipes")
    if list then
        for i = 0, list:size() - 1 do
            local ins = call(list:get(i), "getInputs")
            if ins then
                for j = 0, ins:size() - 1 do
                    local poss = call(ins:get(j), "getPossibleInputItems")
                    if poss then
                        for k = 0, poss:size() - 1 do
                            local it = poss:get(k)
                            local ft = call(it, "getFullName") or call(it, "getFullType")
                            if ft then set[ft] = true end
                        end
                    end
                end
            end
        end
    end
    st.inTypes = set
    return set
end

-- Snapshot of the machine: inputs waiting, items drying (with progress),
-- outputs, and what the player carries that the rack accepts.
local function gather(st, player)
    local comp = st.comp
    local d = { waiting = {}, drying = {}, outputs = {}, bag = {}, cap = 0, outCap = 0 }

    local ins = comp and call(comp, "getInputResources")
    if ins then
        for i = 0, ins:size() - 1 do
            local r = ins:get(i)
            local items = r and call(r, "getStoredItems")
            if items then
                d.inRes = d.inRes or r
                d.cap = d.cap + (call(r, "getItemCapacity") or 0)
                for j = 0, items:size() - 1 do
                    d.waiting[#d.waiting + 1] = { item = items:get(j), res = r }
                end
            end
        end
    end

    local outs = comp and call(comp, "getOutputResources")
    if outs then
        for i = 0, outs:size() - 1 do
            local r = outs:get(i)
            local items = r and call(r, "getStoredItems")
            if items then
                d.outCap = d.outCap + (call(r, "getItemCapacity") or 0)
                for j = 0, items:size() - 1 do
                    d.outputs[#d.outputs + 1] = { item = items:get(j), res = r }
                end
            end
        end
    end

    d.running = call(comp, "isRunning") and true or false
    -- The recipe follows what is loaded: the running one, else what the
    -- waiting items would make, else none
    if d.running then
        d.recipe = call(comp, "getCurrentRecipe")
    elseif #d.waiting > 0 then
        d.recipe = call(comp, "getPossibleRecipe")
    end
    d.canStart = (not d.running) and (call(comp, "canStart", player) and true or false) or false

    -- Items drying, each craft with its own progress
    local logic = uiLogic(st, player)
    local prog = logic and call(logic, "getItemsInProgress")
    local pSum, pN = 0, 0
    if prog then
        for crd, sub in pairs(prog) do
            local p = call(comp, "getProgress", crd) or 0
            pSum, pN = pSum + p, pN + 1
            -- sub: item -> count (a Lua table built on the Java side)
            pcall(function()
                for item, count in pairs(sub) do
                    local n = tonumber(tostring(count)) or 1   -- a Java number: read it through its text
                    for _ = 1, math.max(1, math.min(n, 64)) do
                        d.drying[#d.drying + 1] = { item = item, p = p }
                    end
                end
            end)
        end
    end
    d.progress = pN > 0 and (pSum / pN) or 0
    local t = d.recipe and call(d.recipe, "getTime") or nil
    d.time = t
    d.left = (d.running and t) and (1 - d.progress) * t or nil

    -- What the player carries that the rack takes, grouped by type
    if d.inRes then
        local conts = ZeD.CraftingCore.buildContainers(player)
        local fits = inputTypes(st)
        local groups = {}
        for i = 0, conts:size() - 1 do
            local c = conts:get(i)
            local items = c and call(c, "getItems")
            if items then
                for j = 0, items:size() - 1 do
                    local it = items:get(j)
                    if it and fits[it:getFullType()] and not player:isEquipped(it) and call(d.inRes, "acceptsItem", it) then
                        local ft = it:getFullType()
                        local g = groups[ft]
                        if not g then
                            g = { type = ft, name = nameOf(it), tex = texOf(it), items = {}, where = containerLabel(c, player) }
                            groups[ft] = g
                            d.bag[#d.bag + 1] = g
                        end
                        g.items[#g.items + 1] = it
                    end
                end
            end
        end
        table.sort(d.bag, function(a, b) return a.name < b.name end)
    end
    return d
end

local function data(st, player)
    st._mdT = (st._mdT or REFRESH) + 1
    if st._mdT >= REFRESH or not st._md then
        st._mdT = 0
        st._md = gather(st, player)
    end
    return st._md
end

local function dirty(st) st._mdT = REFRESH end

-- ----------------------------------------------------------------------------
-- ACTIONS (all walk to the rack first, as vanilla does)
-- ----------------------------------------------------------------------------
local function walk(player, st)
    return ISEntityUI and ISEntityUI.WalkToEntity and ISEntityUI.WalkToEntity(player, st.obj)
end

function SM.add(player, st, group)
    local d = st._md
    local res = d and d.inRes
    if not (res and group) then return end
    if not walk(player, st) then return end
    local free = call(res, "getFreeItemCapacity") or 0
    local outFree = call(st.comp, "getFreeOutputSlotCount")
    local maxItems = free
    if outFree then maxItems = math.min(free, math.max(0, outFree - (call(res, "storedSize") or 0))) end
    for i, it in ipairs(group.items) do
        if i > maxItems then break end
        local a = ISItemSlotAddAction:new(player, st.obj, it, res, nil)
        a.component = st.comp
        a.canAddItem = function(self)
            return self.component:getFreeOutputSlotCount() - self.resource:storedSize() > 0
        end
        ISTimedActionQueue.add(a)
    end
    dirty(st)
end

function SM.take(player, st, entries)
    if not (entries and #entries > 0) then return end
    if not walk(player, st) then return end
    for _, e in ipairs(entries) do
        ISTimedActionQueue.add(ISItemSlotRemoveAction:new(player, st.obj, e.res, nil, e.item))
    end
    dirty(st)
end

function SM.start(player, st)
    if not (ISEntityUI and ISEntityUI.GenericCraftStart) then return end
    ISEntityUI.GenericCraftStart(player, st.obj, st.comp,
        function(p, e, c) return c:canStart(p) end,
        function(p, e, c) c:start(p) end)
    dirty(st)
end

function SM.stop(player, st)
    if not (ISEntityUI and ISEntityUI.GenericCraftStart) then return end
    ISEntityUI.GenericCraftStart(player, st.obj, st.comp,
        function() return true end,
        function(p, e, c) c:stop(p) end)
    dirty(st)
end

-- ----------------------------------------------------------------------------
-- RENDER
-- ----------------------------------------------------------------------------
local function gridRows(n) return math.max(1, math.ceil(n / COLS)) end

-- One slot. kind: "dry" (with progress), "wait", "out", "empty".
local function drawCell(panel, x, y, w, h, kind, item, p, focused, hovered)
    local T = ZeD.T
    if kind == "empty" then
        local b = T.border
        panel:drawRectBorder(x, y, w, h, (b.a or 1) * 0.6, b.r, b.g, b.b)
        return
    end
    local s2 = T.surf2
    panel:drawRect(x, y, w, h, s2.a, s2.r, s2.g, s2.b)
    if hovered then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    panel:drawRectBorder(x, y, w, h, T.border.a, T.border.r, T.border.g, T.border.b)
    local isz = T.px(20)
    local tex = item and texOf(item)
    if tex then
        panel:drawTextureScaledAspect(tex, x + math.floor((w - isz) / 2), y + T.px(4), isz, isz, 1, 1, 1, 1)
    end
    if kind == "dry" then
        local bx, bw, bh = x + T.px(3), w - T.px(6), T.px(4)
        local by = y + h - T.px(3) - bh
        local s3 = T.surf3
        panel:drawRect(bx, by, bw, bh, s3.a, s3.r, s3.g, s3.b)
        local ac = T.accent
        panel:drawRect(bx, by, math.floor(bw * math.max(0, math.min(1, p or 0))), bh, 1, ac.r, ac.g, ac.b)
    end
    if focused then
        local ac = T.accent
        panel:drawRect(x, y, w, h, 0.55, ac.r, ac.g, ac.b)
    end
end

local function label(panel, text, x, y, h, color)
    local T = ZeD.T
    local f = T.fontF1
    local c = color or T.accent
    panel:drawText(text, x, y + math.floor((h - ZeD.TM:getFontHeight(f)) / 2), c.r, c.g, c.b, c.a or 1, f)
    return ZeD.TM:MeasureStringX(f, text)
end

function SM.render(panel, win, x, y, w, h, state, st)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local M  = ZeD.Molecules
    local tm = ZeD.TM
    local player = win._playerObj
    state._lastZones = state.zones
    state.zones = {}
    state._gpFocusedId = ST.focusedId(win)
    local fid = state._gpFocusedId
    local zones = state.zones

    local headH = ST.renderViewHeader(panel, win, x, y, w, state, st)
    local d = data(st, player)

    -- Body metrics (screen px)
    local pad, gap = T.px(PAD), T.px(8)
    local rowH, cellH, cg = T.px(ROW_H), T.px(CELL_H), T.px(GAP)
    local inRows = gridRows(math.max(d.cap, #d.drying + #d.waiting))
    local outRows = gridRows(math.max(COLS, #d.outputs))
    local bagN = math.max(1, #d.bag)
    local totalH = pad + rowH + gap + rowH + inRows * cellH + (inRows - 1) * cg + gap
        + rowH + gap + rowH + outRows * cellH + (outRows - 1) * cg + gap
        + rowH + bagN * rowH + pad

    local viewY, viewH = y + headH, h - headH
    local scroll = state.scroll
    local needsScroll = totalH > viewH
    scroll.visible = needsScroll
    local scrollW = T.sp.scrollbarW
    local cw = needsScroll and (w - scrollW) or w
    local off = 0
    if needsScroll then
        scroll.x, scroll.y, scroll.height = x + w - scrollW, viewY, viewH
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

    -- RECIPE line
    local lw = label(panel, ZeD.tr("UI_ZeD_Machine_Recipe"), lx, cy, rowH)
    local rname = d.recipe and (call(d.recipe, "getTranslationName") or call(d.recipe, "getName")) or getText("UI_None")
    local nf = T.fontF2
    local tc = d.recipe and T.text or T.textDim
    local dur = d.time and durationText(d.time) or ""
    local durW = tm:MeasureStringX(T.fontF1, dur)
    panel:drawText(ZeD.CraftingCore.truncText(rname, nf, iw - lw - durW - T.px(20)), lx + lw + T.px(8),
        cy + math.floor((rowH - tm:getFontHeight(nf)) / 2), tc.r, tc.g, tc.b, tc.a or 1, nf)
    if dur ~= "" then A.drawTextRight(panel, dur, rx, cy + math.floor((rowH - tm:getFontHeight(T.fontF1)) / 2), T.fontF1, T.textDim) end
    cy = cy + rowH + gap

    -- INPUT grid: drying first (with progress), then waiting, then empty
    lw = label(panel, ZeD.tr("UI_ZeD_Machine_Input"), lx, cy, rowH)
    label(panel, tostring(#d.drying + #d.waiting) .. " / " .. tostring(d.cap), lx + lw + T.px(8), cy, rowH, T.textDim)
    cy = cy + rowH
    local cellW = math.floor((iw - (COLS - 1) * cg) / COLS)
    local slots = {}
    for _, e in ipairs(d.drying) do slots[#slots + 1] = { kind = "dry", e = e } end
    for _, e in ipairs(d.waiting) do slots[#slots + 1] = { kind = "wait", e = e } end
    for i = 1, inRows * COLS do
        local s = slots[i]
        local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
        local sx, sy = lx + col * (cellW + cg), cy + row * (cellH + cg)
        if i <= math.max(d.cap, #slots) then
            local kind = s and s.kind or "empty"
            local id = "craft:m:in:" .. tostring(i)
            drawCell(panel, sx, sy, cellW, cellH, kind, s and s.e.item, s and s.e.p, fid == id, kind == "wait" and hov(sx, sy, cellW, cellH))
            if kind == "wait" then
                zones[#zones + 1] = { type = "mInRemove", fid = id, entry = s.e, x = sx, y = sy, w = cellW, h = cellH }
            elseif kind == "dry" then
                zones[#zones + 1] = { type = "mInfo", fid = id, x = sx, y = sy, w = cellW, h = cellH }
            end
        end
    end
    cy = cy + inRows * cellH + (inRows - 1) * cg + gap

    -- START / STOP + progress
    local bw, bh = T.px(70), T.px(22)
    local by = cy + math.floor((rowH - bh) / 2)
    local btnLabel = ZeD.tr(d.running and "UI_ZeD_Machine_Stop" or "UI_ZeD_Machine_Start")
    local enabled = d.running or d.canStart
    if enabled then
        M.drawButton(panel, lx, by, bw, bh, btnLabel, d.running and "default" or "primary")
    else
        local bd = T.textDim
        A.borderRounded(panel, lx, by, bw, bh, bd.r, bd.g, bd.b, (bd.a or 1) * 0.5)
        local f = T.fontF3
        panel:drawText(btnLabel, lx + math.floor((bw - tm:MeasureStringX(f, btnLabel)) / 2), by + math.floor((bh - tm:getFontHeight(f)) / 2),
            bd.r, bd.g, bd.b, (bd.a or 1) * 0.5, f)
    end
    if fid == "craft:m:start" then
        local ac = T.accent
        panel:drawRect(lx, by, bw, bh, 0.55, ac.r, ac.g, ac.b)
    end
    zones[#zones + 1] = { type = "mStart", fid = "craft:m:start", enabled = enabled, running = d.running, x = lx, y = by, w = bw, h = bh }
    local ptxt = ""
    if d.running then
        ptxt = tostring(math.floor(d.progress * 100 + 0.5)) .. "%"
        if d.left then ptxt = ptxt .. "  " .. ST.DOT .. "  " .. ZeD.tr("UI_ZeD_Machine_Left", aboutTime(d.left)) end
    end
    local ptw = tm:MeasureStringX(T.fontF3, ptxt)
    local px0 = lx + bw + T.px(8)
    local pbw = math.max(T.px(30), rx - px0 - (ptw > 0 and (ptw + T.px(8)) or 0))
    local pbh = T.px(8)
    local pby = cy + math.floor((rowH - pbh) / 2)
    local s2 = T.surf2
    panel:drawRect(px0, pby, pbw, pbh, s2.a, s2.r, s2.g, s2.b)
    panel:drawRectBorder(px0, pby, pbw, pbh, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    if d.running then
        local ac = T.accent
        panel:drawRect(px0 + T.px(1), pby + T.px(1), math.floor((pbw - T.px(2)) * d.progress), pbh - T.px(2), 1, ac.r, ac.g, ac.b)
    end
    if ptw > 0 then
        A.drawTextRight(panel, ptxt, rx, cy + math.floor((rowH - tm:getFontHeight(T.fontF3)) / 2), T.fontF3, T.text)
    end
    cy = cy + rowH + gap

    -- OUTPUT grid + TAKE ALL
    lw = label(panel, ZeD.tr("UI_ZeD_Machine_Output"), lx, cy, rowH)
    label(panel, tostring(#d.outputs), lx + lw + T.px(8), cy, rowH, T.textDim)
    if #d.outputs > 0 then
        local tw = T.px(80)
        local ty = cy + math.floor((rowH - bh) / 2)
        M.drawButton(panel, rx - tw, ty, tw, bh, ZeD.tr("UI_ZeD_Machine_TakeAll"), "primary")
        if fid == "craft:m:takeAll" then
            local ac = T.accent
            panel:drawRect(rx - tw, ty, tw, bh, 0.55, ac.r, ac.g, ac.b)
        end
        zones[#zones + 1] = { type = "mTakeAll", fid = "craft:m:takeAll", x = rx - tw, y = ty, w = tw, h = bh }
    end
    cy = cy + rowH
    for i = 1, outRows * COLS do
        local e = d.outputs[i]
        local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
        local sx, sy = lx + col * (cellW + cg), cy + row * (cellH + cg)
        local id = "craft:m:out:" .. tostring(i)
        drawCell(panel, sx, sy, cellW, cellH, e and "out" or "empty", e and e.item, nil, fid == id, e and hov(sx, sy, cellW, cellH))
        if e then zones[#zones + 1] = { type = "mOutTake", fid = id, entry = e, x = sx, y = sy, w = cellW, h = cellH } end
    end
    cy = cy + outRows * cellH + (outRows - 1) * cg + gap

    -- FROM YOUR BAGS
    lw = label(panel, ZeD.tr("UI_ZeD_Machine_FromBags"), lx, cy, rowH)
    cy = cy + rowH
    if #d.bag == 0 then
        panel:drawText(ZeD.tr("UI_ZeD_Machine_NothingFits"), lx, cy + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2),
            T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF2)
    end
    for _, g in ipairs(d.bag) do
        local id = "craft:m:add:" .. g.type
        local isz = T.px(16)
        if g.tex then panel:drawTextureScaledAspect(g.tex, lx, cy + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local addW = T.px(48)
        local where = g.where or ""
        local whereW = tm:MeasureStringX(T.fontF1, where)
        local nameMax = rx - addW - T.px(8) - whereW - T.px(8) - (lx + isz + T.px(6))
        local nstr = ZeD.CraftingCore.truncText(g.name .. "  x" .. tostring(#g.items), T.fontF2, nameMax)
        panel:drawText(nstr, lx + isz + T.px(6), cy + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2),
            T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
        A.drawTextRight(panel, where, rx - addW - T.px(8), cy + math.floor((rowH - tm:getFontHeight(T.fontF1)) / 2), T.fontF1, T.textDim)
        local ay = cy + math.floor((rowH - T.px(20)) / 2)
        M.drawButton(panel, rx - addW, ay, addW, T.px(20), ZeD.tr("UI_ZeD_Machine_Add"), "default")
        if fid == id then
            local ac = T.accent
            panel:drawRect(rx - addW, ay, addW, T.px(20), 0.55, ac.r, ac.g, ac.b)
        end
        zones[#zones + 1] = { type = "mAdd", fid = id, group = g, x = rx - addW, y = ay, w = addW, h = T.px(20) }
        A.drawDividerH(panel, lx, cy + rowH - T.px(1), iw, false)
        cy = cy + rowH
    end

    panel:clearStencilRect()
    if needsScroll then scroll:draw(panel) end

    -- Station dropdown overlay last
    ST.drawDropdownFor(panel, state, player, fid, "craft")
end

-- ----------------------------------------------------------------------------
-- INPUT
-- ----------------------------------------------------------------------------
local function hit(z, x, y) return x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end

local function activate(player, st, z)
    if z.type == "mInRemove" then SM.take(player, st, { z.entry })
    elseif z.type == "mOutTake" then SM.take(player, st, { z.entry })
    elseif z.type == "mTakeAll" then SM.take(player, st, st._md and st._md.outputs or {})
    elseif z.type == "mAdd" then SM.add(player, st, z.group)
    elseif z.type == "mStart" then
        if z.running then SM.stop(player, st) elseif z.enabled then SM.start(player, st) end
    end
end

function SM.onClick(win, state, st, x, y)
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

function SM.onMouseWheel(win, state, st, del, x, y)
    if state.stDropdownOpen then return ST.dropdownWheel(state, del) end
    if state.scroll and state.scroll.visible then state.scroll:handleMouseWheel(del) end
    return true
end

function SM.buildFocusables(win, state, st)
    if state.stDropdownOpen then return ST.dropdownFocusables(state, win._playerObj, "craft") end
    local out = {}
    local sel = ST.selectFocusable(state)
    if sel then out[#out + 1] = sel end
    for _, z in ipairs(state.zones or {}) do
        if z.fid and z.type ~= "mInfo" then
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

-- Rebuild focusables when the machine's contents change shape.
function SM.focusKey(win, state, st)
    local d = st._md
    if not d then return "m" end
    return "m" .. tostring(#d.waiting) .. "/" .. tostring(#d.drying) .. "/" .. tostring(#d.outputs) .. "/"
        .. tostring(#d.bag) .. "/" .. tostring(d.running) .. "/" .. tostring(state.scroll and state.scroll.scrollPos or 0)
end

print("[ZeD] StationMachine: drying rack view loaded")
return SM
