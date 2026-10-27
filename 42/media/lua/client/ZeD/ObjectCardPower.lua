-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardPower.lua
-- ============================================================================
-- OBJECT CARD: GENERATOR (HOOK_MAP row 11; mockup zed_info_cards_v1.html)
-- The generator's own front panel in pixel art (director, Oct 16 2026: one
-- plate per model): the red 1988 portable, the yellow contractor's set, the
-- blue compact and the 1960s military set (ZeDUI/tools/physpx, data in
-- PhysPx.lua, drawn by the shared plate template ZeD_Plate.lua; the plate is
-- picked by the generator's item). Live on it: the engine switch and its lamp,
-- the fuel gauge, the building's cord in the outlet, the OIL lamp (condition
-- under a quarter), the meters (120 volts and 60 cycles while it runs, the
-- load it carries). The engine switch turns it on or off and the outlet
-- connects or disconnects it, with vanilla's rules. Under the plate: the run
-- time left at the current draw and the fuel in litres; then condition, what
-- it powers in L/h, the indoor fumes warning, and vanilla's generator actions
-- as header verbs:
--   TURN ON / OFF  ISActivateGenerator (on needs it connected and fuel; at 50%
--                  condition or less it can fail to start, vanilla rolls that)
--   ADD FUEL       ISAddFuel per petrol can (off, under a full tank)
--   FIX            ISFixGenerator (off, under 100%, Scrap Electronics,
--                  Electricity 3 or the generator magazine)
--   CONNECT / DISCONNECT  ISPlugGenerator (off, same skill)
--   TAKE           ISTakeGenerator (disconnected)
-- All actions go through vanilla's own handlers (walk-adjacent included).
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

local OC = ZeD.ObjectCards
local P = ZeD.Px
local PL = ZeD.Plate
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local OIL_COND = 25           -- the OIL lamp lights under a quarter's condition (director, Oct 16 2026)
-- The load meters' full scale: L/h burnt above the engine's own idle. Calibrated (Oct 16 2026) against vanilla's
-- own figures (IsoGenerator, B42): idle 0.02; fridge and freezer together 0.13, a lone fridge or freezer 0.08; a
-- stove, washer or dryer 0.09 each while running; a television 0.03, a radio 0.01; a battery charger 0.05; a light
-- switch 0.002 while lit; a stacked washer-dryer 0.9 (ten times the others; vanilla's figure). So a lived-in house
-- reads: the fridge and a few lights about a third of the scale, cooking on top about half, a whole house running
-- everything nine tenths, and a second house on the same generator pins the needle. Past full scale the OVERLOAD lamp
-- lights (the blue set's): vanilla adds no penalty, but the fuel burns that much faster.
local LOAD_FULL = 0.5

ZeD.ObjectCardPower = ZeD.ObjectCardPower or {}
ZeD.ObjectCardPower.LOAD_FULL = LOAD_FULL

local function isGenerator(o) return o ~= nil and instanceof(o, "IsoGenerator") end

local function canElectric(player)
    return player:getPerkLevel(Perks.Electricity) >= 3 or (call(player, "isRecipeActuallyKnown", "Generator") == true)
end

local function scriptItem(fullType)
    local sm = getScriptManager and getScriptManager()
    return sm and fullType and call(sm, "FindItem", fullType) or nil
end

-- "Fridge (0.0800 L/h)" -> "Fridge", "0.0800 L/h" (the value as vanilla writes it)
local function splitPowered(s)
    s = tostring(s or "")
    local name, val = string.match(s, "^(.-)%s*%(([^%(%)]*)%)%s*$")
    if not name then return s, nil end
    return name, val
end

local function petrolCans(player)
    local out = {}
    local inv = player:getInventory()
    local list = inv:getAllEvalRecurse(function(item)
        local fc = item:getFluidContainer()
        return fc ~= nil and fc:contains(Fluid.Petrol)
    end)
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        local fc = it:getFluidContainer()
        out[#out + 1] = {
            item = it,
            amt = fc:getAmount(),
            cap = fc:getCapacity(),
            name = it:getDisplayName(),
            tex = it:getTex(),
            where = OC.whereOf(it, player),
        }
    end
    table.sort(out, function(a, b) return a.amt > b.amt end)
    return out
end

local def = { id = "generator" }

function def.resolve(player, obj)
    if not isGenerator(obj) then return nil end
    local sq = obj:getSquare()
    if not sq then return nil end
    return { obj = obj, sq = sq, key = OC.keyOf(sq, "gen") }
end

function def.valid(t)
    return t.obj ~= nil and t.obj:getSquare() ~= nil and t.obj:getObjectIndex() ~= -1
end

function def.nearby(player)
    local list = {}
    OC.eachSquare(player, OC.LEASH, function(sq)
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if isGenerator(o) then list[#list + 1] = def.resolve(player, o) end
        end
    end)
    return OC.sortTargets(list)
end

function def.refresh(t, player)
    local g = t.obj
    local d = {}
    d.fuel = g:getFuel() or 0
    d.max = call(g, "getMaxFuel") or 10
    if d.max <= 0 then d.max = 10 end
    d.pct = g:getFuelPercentage() or 0
    d.cond = g:getCondition() or 0
    d.on = g:isActivated()
    d.conn = g:isConnected()
    d.base = call(g, "getBasePowerConsumption") or 0
    d.total = call(g, "getTotalPowerUsing") or 0
    d.totalStr = call(g, "getTotalPowerUsingString")
    d.baseStr = call(g, "getBasePowerConsumptionString")
    d.items = {}
    local ip = call(g, "getItemsPowered")
    if ip then
        for i = 0, ip:size() - 1 do
            local name, val = splitPowered(ip:get(i))
            d.items[#d.items + 1] = { name = name, val = val }
        end
    end
    local sq = g:getSquare()
    d.toxic = sq ~= nil and not sq:isOutside() and sq:getBuilding() ~= nil
    d.itemType = call(g, "getGeneratorItemType")
    local si = scriptItem(d.itemType)
    d.name = (si and call(si, "getDisplayName")) or getText("ContextMenu_Generator")
    d.tex = si and call(si, "getNormalTexture") or nil
    d.cans = (not d.on and d.pct < 100) and petrolCans(player) or {}
    d.elec = canElectric(player)
    d.scrap = player:getInventory():getFirstTypeRecurse("ElectronicsScrap") ~= nil
    t.d = d

    -- verbs, with vanilla's rules. Running, adding fuel, fixing, connecting and taking it all wait
    -- for one thing the player can do right here: turn it off (the need "the generator turned off").
    local verbs = {}
    local onOK = d.on or (d.conn and d.fuel > 0)
    local function toggle(p, tt)
        ISWorldObjectContextMenu.onActivateGenerator(nil, not tt.obj:isActivated(), tt.obj, p:getPlayerNum())
    end
    t.toggle = onOK and toggle or nil
    t.plug = nil                       -- the outlet: only while it is off (below)
    local off = not d.on
    local fuelOK = off and d.pct < 100 and #d.cans > 0
    local fixOK = off and d.cond < 100 and d.elec and d.scrap
    local plugOK = off and d.elec
    local takeOK = off and not d.conn
    local primary = (d.on and "power") or (d.fuel <= 0 and fuelOK and "fuel") or (onOK and "power") or (not d.conn and plugOK and "plug") or nil
    -- what each waits for: the engine stopped first, then what it needs of its own
    local NEED_OFF = ZeD.tr("UI_ZeD_Power_NeedsOff")
    verbs[#verbs + 1] = { id = "fuel", label = getText("ContextMenu_GeneratorAddFuel"), enabled = fuelOK, primary = primary == "fuel", jump = "gen:can:1",
        sensible = d.pct < 100, needs = off and ZeD.tr("UI_ZeD_Power_NeedsCan") or NEED_OFF, hint = ZeD.tr("UI_ZeD_Power_HintFuel"),
        help = ZeD.tr("UI_ZeD_Power_HelpFuel") }
    verbs[#verbs + 1] = { id = "power", label = getText(d.on and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On"), enabled = onOK, primary = primary == "power", run = toggle,
        needs = ZeD.tr(d.fuel <= 0 and "UI_ZeD_Power_NeedsFuel" or "UI_ZeD_Power_NeedsConnected"), hint = ZeD.tr("UI_ZeD_Power_HintOn"),
        help = ZeD.tr(d.on and "UI_ZeD_Power_HelpOff" or "UI_ZeD_Power_HelpOn") }
    verbs[#verbs + 1] = { id = "fix", label = ZeD.tr("UI_ZeD_Power_Fix"), enabled = fixOK, sensible = d.cond < 100,
        needs = off and ZeD.tr(d.elec and "UI_ZeD_Power_NeedsScrap" or "UI_ZeD_Power_NeedsElec") or NEED_OFF, hint = ZeD.tr("UI_ZeD_Power_HintFix"),
        help = ZeD.tr("UI_ZeD_Power_HelpFix"),
        run = function(p, tt) ISWorldObjectContextMenu.onFixGenerator(nil, tt.obj, p:getPlayerNum()) end }
    local plug = function(p, tt) ISWorldObjectContextMenu.onPlugGenerator(nil, tt.obj, p:getPlayerNum(), not tt.obj:isConnected()) end
    t.plug = plugOK and plug or nil
    verbs[#verbs + 1] = { id = "plug", label = d.conn and ZeD.tr("UI_ZeD_Power_Disconnect") or ZeD.tr("UI_ZeD_Power_Connect"), enabled = plugOK, primary = primary == "plug",
        needs = off and ZeD.tr("UI_ZeD_Power_NeedsElec") or NEED_OFF, hint = ZeD.tr(d.conn and "UI_ZeD_Power_HintDisconnect" or "UI_ZeD_Power_HintConnect"),
        help = ZeD.tr(d.conn and "UI_ZeD_Power_HelpDisconnect" or "UI_ZeD_Power_HelpConnect"), run = plug }
    verbs[#verbs + 1] = { id = "take", label = getText("ContextMenu_Take"), enabled = takeOK,
        needs = off and ZeD.tr("UI_ZeD_Power_NeedsDisconnected") or NEED_OFF, hint = ZeD.tr("UI_ZeD_Power_HintTake"),
        help = ZeD.tr("UI_ZeD_Power_HelpTake"),
        run = function(p, tt) ISWorldObjectContextMenu.onTakeGenerator(nil, tt.obj, p:getPlayerNum()) end }
    t.verbs = verbs
end

function def.title(t) return t.d and t.d.name or getText("ContextMenu_Generator") end
function def.icon(t) return t.d and t.d.tex or nil end
-- the state tag: its words, and the colour of its square mark (none for a plain tag)
function def.pill(t)
    local T = ZeD.T
    if t.d and t.d.on then return ZeD.tr("UI_ZeD_Power_PillRunning"), T.positive end
    return ZeD.tr("UI_Off"), T.textDim
end

-- "33:20" from hours
local function hhmm(hours)
    if not hours or hours <= 0 then return "00:00" end
    local h = math.floor(hours)
    local m = math.floor((hours - h) * 60)
    if h > 99 then return "99:59" end
    return (h < 10 and "0" or "") .. tostring(h) .. ":" .. (m < 10 and "0" or "") .. tostring(m)
end

-- the plate for this generator: by its item, else the one a modded set borrows
local function plateFor(d)
    local X = ZeD.PhysPx
    local id = X and (X.items[d.itemType or ""] or X.fallback.generator) or nil
    return X and X.plates[id] or nil
end
local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end

-- what the plate's live parts read
local function plateState(d)
    local st = {}
    st.running = d.on
    st.connected = d.conn or d.on
    st.fuel = math.max(0, math.min(1, d.fuel / d.max))
    st.service = d.cond < OIL_COND
    st.volts = d.on and 1 or 0
    st.hz = d.on and 1 or 0
    -- the load: what the powered things burn above the engine's own idle, in the sandbox's units
    local fac = tonumber(SandboxVars and SandboxVars.GeneratorFuelConsumption) or 1
    if fac <= 0 then fac = 1 end
    local extra = math.max(0, (d.total or 0) - (d.base or 0)) / fac
    st.load = d.on and math.max(0, math.min(1, extra / LOAD_FULL)) or 0
    st.overload = d.on and extra > LOAD_FULL or false
    return st
end

ZeD.ObjectCardPower.plateState = plateState

-- the plate (fixed size, centred), its two controls, and the line under it
local function drawPlate(card, x, y, w, t)
    local T = ZeD.T
    local d = t.d
    local des = plateFor(d)
    if not des then return 0 end
    local Sc = ZeD.Scale
    local k = P.kFit((Sc and Sc.root and Sc.root()) or 1, des.w, w)   -- whole zoom, inside the card
    local px0 = x + PL.centre(w, des.w, k)
    local cv = P.canvas(card, px0, y, k)
    local st = plateState(d)
    PL.draw(cv, des, st, { tex = plateTex, now = getTimestampMs() })
    -- the engine switch turns it on / off; the outlet connects / disconnects (vanilla's rules: t.toggle, t.plug)
    for _, c in ipairs(PL.controls(des, st)) do
        local fid = "gen:" .. c.id
        local fn = (c.id == "engine" and t.toggle) or (c.id == "outlet" and t.plug) or nil
        -- a key (the outlet) takes the pointer's wash and the controller's mark; a knob or
        -- rocker keeps its own lit cue
        if c.kind == "turn" then
            if card._fid == fid then PL.cue(cv, c, T.accent, 0.55) end
        else
            if UI.hovered(card, fid) then PL.hoverKey(cv, c) end
            local fm = card:focusOf(fid)
            if fm then PL.markKey(card, c, px0, y, k, fm) end
        end
        card:zone({ fid = fid, x = px0 + c.x * k, y = y + c.y * k, w = c.w * k, h = c.h * k, body = true,
            help = (c.id == "engine" and ZeD.tr("UI_ZeD_Power_HelpEngine")) or (c.id == "outlet" and ZeD.tr("UI_ZeD_Power_HelpOutlet")) or nil,
            run = fn and function(cc, p) fn(p, t) end or nil })
    end
    local h = des.h * k + T.px(6)
    -- getTotalPowerUsing already carries the sandbox fuel factor: it is the
    -- litres burnt per game hour, so fuel / draw is the run time left
    local hrs, unitKey = "--:--", "UI_ZeD_Power_Hrs"
    if d.on then
        local draw = (d.total and d.total > 0) and d.total or d.base
        if draw and draw > 0 then
            local hh = d.fuel / draw
            if hh >= 100 then
                local days = math.floor(hh / 24)
                hrs, unitKey = (days > 999) and "999+" or tostring(days), "UI_ZeD_Power_Days"
            else
                hrs = hhmm(hh)
            end
        end
    elseif d.fuel <= 0 then
        hrs = "00:00"
    end
    h = h + UI.pair(card, x, y + h, w, ZeD.tr("UI_ZeD_Power_RunTimeLeft"), ZeD.tr(unitKey, hrs), ZeD.tr("UI_ZeD_Power_Fuel"),
        ZeD.tr("UI_ZeD_Power_FuelOf", string.format("%.1f", d.fuel), math.floor(d.max + 0.5)))
    return h
end

function def.body(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    if not d then return 0 end
    local y0 = y
    local gap = T.px(8)
    if d.toxic then
        y = y + UI.warn(card, x, y, w, ZeD.tr("UI_ZeD_Power_Fumes")) + gap
    end
    y = y + drawPlate(card, x, y, w, t) + gap

    -- condition
    local condC = d.cond > 50 and T.positive or T.warning
    local condTxt = tostring(d.cond) .. "%"
    if d.cond <= 50 then condTxt = ZeD.tr("UI_ZeD_Power_MayFail", condTxt) end
    y = y + UI.meter(card, x, y, w, ZeD.tr("IGUI_invpanel_Condition"), condTxt, d.cond <= 50 and T.warning or nil, d.cond, condC) + gap

    if d.on then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Power_Powering"), tostring(#d.items))
        for _, it in ipairs(d.items) do
            y = y + UI.row(card, x, y, w, nil, it.name, it.val)
        end
        y = y + UI.row(card, x, y, w, nil, d.name, d.baseStr)
        local tf = T.fontF3
        local th = T.px(24)
        local tc = T.text
        local totalStr = d.totalStr or string.format("%.4f L/h", d.total or 0)
        ZeD.Atoms.drawTextRight(card, totalStr, x + w - T.px(2), y + math.floor((th - ZeD.TM:getFontHeight(tf)) / 2), tf, tc)
        local totalTxt = ZeD.tr("IGUI_Total")
        local lw = ZeD.TM:MeasureStringX(tf, totalTxt)
        local vw = ZeD.TM:MeasureStringX(tf, totalStr)
        card:drawText(totalTxt, x + w - T.px(2) - vw - T.px(12) - lw, y + math.floor((th - ZeD.TM:getFontHeight(tf)) / 2), tc.r, tc.g, tc.b, tc.a or 1, tf)
        y = y + th
    elseif #d.cans > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Fire_AddFromBags"), ZeD.tr("UI_ZeD_Fire_Adds"))
        local room = math.max(0, d.max - d.fuel)
        for i, c in ipairs(d.cans) do
            local add = math.min(c.amt, room)
            local cc = c
            y = y + UI.pick(card, x, y, w, {
                tex = c.tex,
                name = ZeD.tr("UI_ZeD_Power_CanName", c.name, string.format("%.1f", c.amt), math.floor(c.cap + 0.5)),
                where = c.where,
                gain = string.format("+%.1f L", add),
                button = getText("UI_btn_add"),
                fid = "gen:can:" .. i,
                enabled = room > 0,
                help = ZeD.tr("UI_ZeD_Power_HelpAddCan", c.name),
                run = function(card2, p)
                    ISWorldObjectContextMenu.doAddFuelGenerator(nil, t.obj, {}, cc.item, p:getPlayerNum())
                end,
            })
        end
    end
    return y - y0
end

OC.register(def)
