-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardPower.lua
-- ============================================================================
-- OBJECT CARD: GENERATOR (HOOK_MAP row 11; mockup zed_info_cards_v1.html)
-- Faceplate (fuel needle, run / low-fuel / line lamps, hours left at the
-- current draw, I / O rocker), condition, what it powers in L/h, the indoor
-- fumes warning, and vanilla's generator actions as header verbs:
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

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local LOW_FUEL_PCT = 20

local function isGenerator(o) return o ~= nil and instanceof(o, "IsoGenerator") end

local function canElectric(player)
    return player:getPerkLevel(Perks.Electricity) >= 3 or (call(player, "isRecipeActuallyKnown", "Generator") == true)
end

local function scriptItem(fullType)
    local sm = getScriptManager and getScriptManager()
    return sm and fullType and call(sm, "FindItem", fullType) or nil
end

-- "Fridge (0.0800 L/h)" -> "Fridge", "0.0800 L/H"
local function splitPowered(s)
    s = tostring(s or "")
    local name, val = string.match(s, "^(.-)%s*%(([^%(%)]*)%)%s*$")
    if not name then return s, nil end
    return name, string.upper(val)
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
    local si = scriptItem(call(g, "getGeneratorItemType"))
    d.name = (si and call(si, "getDisplayName")) or "Generator"
    d.tex = si and call(si, "getNormalTexture") or nil
    d.cans = (not d.on and d.pct < 100) and petrolCans(player) or {}
    d.elec = canElectric(player)
    d.scrap = player:getInventory():getFirstTypeRecurse("ElectronicsScrap") ~= nil
    t.d = d

    -- verbs, with vanilla's rules
    local pn = player:getPlayerNum()
    local verbs, needs = {}, {}
    local onOK = d.on or (d.conn and d.fuel > 0)
    local function toggle(p, tt)
        ISWorldObjectContextMenu.onActivateGenerator(nil, not tt.obj:isActivated(), tt.obj, p:getPlayerNum())
    end
    t.toggle = onOK and toggle or nil
    if d.on then
        verbs[#verbs + 1] = { id = "power", label = "TURN OFF", primary = true, run = toggle }
        verbs[#verbs + 1] = { id = "fuel", label = "ADD FUEL", enabled = false }
        verbs[#verbs + 1] = { id = "fix", label = "FIX", enabled = false }
        verbs[#verbs + 1] = { id = "plug", label = d.conn and "DISCONNECT" or "CONNECT", enabled = false }
        verbs[#verbs + 1] = { id = "take", label = "TAKE", enabled = false }
        needs[#needs + 1] = "Turn it off to add fuel, fix or " .. (d.conn and "disconnect" or "connect") .. " it"
    else
        local fuelOK = d.pct < 100 and #d.cans > 0
        local fixOK = d.cond < 100 and d.elec and d.scrap
        local plugOK = d.elec
        local takeOK = not d.conn
        local primary = (d.fuel <= 0 and fuelOK and "fuel") or (onOK and "power") or (not d.conn and plugOK and "plug") or nil
        verbs[#verbs + 1] = { id = "fuel", label = "ADD FUEL", enabled = fuelOK, primary = primary == "fuel", jump = "gen:can:1" }
        verbs[#verbs + 1] = { id = "power", label = "TURN ON", enabled = onOK, primary = primary == "power", run = toggle }
        verbs[#verbs + 1] = { id = "fix", label = "FIX", enabled = fixOK,
            run = function(p, tt) ISWorldObjectContextMenu.onFixGenerator(nil, tt.obj, p:getPlayerNum()) end }
        verbs[#verbs + 1] = { id = "plug", label = d.conn and "DISCONNECT" or "CONNECT", enabled = plugOK, primary = primary == "plug",
            run = function(p, tt) ISWorldObjectContextMenu.onPlugGenerator(nil, tt.obj, p:getPlayerNum(), not tt.obj:isConnected()) end }
        verbs[#verbs + 1] = { id = "take", label = "TAKE", enabled = takeOK,
            run = function(p, tt) ISWorldObjectContextMenu.onTakeGenerator(nil, tt.obj, p:getPlayerNum()) end }
        if not onOK then
            if d.fuel <= 0 then needs[#needs + 1] = "TURN ON needs fuel"
            elseif not d.conn then needs[#needs + 1] = "TURN ON needs it connected" end
        end
        if d.pct < 100 and #d.cans == 0 then needs[#needs + 1] = "ADD FUEL needs a can with petrol" end
        local plugWord = d.conn and "DISCONNECT" or "CONNECT"
        if not d.elec then
            needs[#needs + 1] = plugWord .. (d.cond < 100 and " and FIX need" or " needs") .. " Electricity 3 or the generator magazine"
        elseif d.cond < 100 and not d.scrap then
            needs[#needs + 1] = "FIX needs Scrap Electronics"
        end
        if d.conn then needs[#needs + 1] = "TAKE needs it disconnected" end
    end
    t.verbs = verbs
    t.needs = needs
end

function def.title(t) return t.d and t.d.name or "Generator" end
function def.icon(t) return t.d and t.d.tex or nil end
function def.pill(t)
    local T = ZeD.T
    if t.d and t.d.on then return "RUNNING", T.positive end
    return "OFF", T.textDim
end

-- "33:20" from hours
local function hhmm(hours)
    if not hours or hours <= 0 then return "00:00" end
    local h = math.floor(hours)
    local m = math.floor((hours - h) * 60)
    if h > 99 then return "99:59" end
    return (h < 10 and "0" or "") .. tostring(h) .. ":" .. (m < 10 and "0" or "") .. tostring(m)
end

local function drawPlate(card, x, y, w, t)
    local T, tm, HW = ZeD.T, ZeD.TM, UI.HW
    local d = t.d
    local ph = T.px(102)
    UI.plate(card, x, y, w, ph, "KNOX POWER " .. DOT .. " 5000 W " .. DOT .. " UNLEADED", "KP-5000-0419")
    local top = y + T.px(12)
    -- fuel needle (left)
    local gx, gy = x + T.px(12) + T.px(39), top + T.px(46)
    UI.needle(card, gx, gy, T.px(33), d.fuel / d.max, "FUEL", true)
    -- rocker (right)
    local rw, rh = T.px(28), T.px(46)
    local rx = x + w - T.px(16) - rw
    local ry = top + T.px(4)
    local focused = card._fid == "gen:rocker"
    UI.rocker(card, rx, ry, rw, rh, d.on, focused, "ENGINE")
    card:zone({ fid = "gen:rocker", x = rx - T.px(2), y = ry - T.px(2), w = rw + T.px(4), h = rh + T.px(4), body = true,
        run = t.toggle and function(c, p) t.toggle(p, t) end or nil })
    -- lamps (left of the rocker)
    local f1 = T.fontF1
    local ledW = T.px(8) + T.px(6) + tm:MeasureStringX(f1, "LOW FUEL")
    local lx = rx - T.px(18) - ledW
    local lstep = T.px(16)
    local ly = top + T.px(8)
    UI.led(card, lx, ly, HW.green, d.on, "RUN")
    UI.led(card, lx, ly + lstep, HW.amber, d.pct < LOW_FUEL_PCT, "LOW FUEL")
    UI.led(card, lx, ly + lstep * 2, HW.green, d.conn, "LINE")
    -- hours-left LCD (middle)
    local mx = gx + T.px(39) + T.px(16)
    local f5 = T.fontF5
    local lab = HW.text
    card:drawText("RUN TIME LEFT", mx, top + T.px(2), lab.r, lab.g, lab.b, 0.7, f5)
    -- getTotalPowerUsing already carries the sandbox fuel factor: it is the
    -- litres burnt per game hour, so fuel / draw is the run time left
    local hrs, unit = "--:--", "HRS"
    if d.on then
        local draw = (d.total and d.total > 0) and d.total or d.base
        if draw and draw > 0 then
            local h = d.fuel / draw
            if h >= 100 then
                local days = math.floor(h / 24)
                hrs, unit = (days > 999) and "999+" or tostring(days), "DAYS"
            else
                hrs = hhmm(h)
            end
        end
    elseif d.fuel <= 0 then
        hrs = "00:00"
    end
    UI.lcd(card, mx, top + T.px(2) + tm:getFontHeight(f5) + T.px(4), hrs, unit)
    local litres = string.format("%.1f OF %d L", d.fuel, math.floor(d.max + 0.5))
    card:drawText(litres, mx, top + T.px(2) + tm:getFontHeight(f5) + T.px(4) + T.px(30) + T.px(5), lab.r, lab.g, lab.b, 0.7, f5)
    return ph
end

function def.body(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    if not d then return 0 end
    local y0 = y
    local gap = T.px(8)
    if d.toxic then
        y = y + UI.warn(card, x, y, w, "Indoors. Running it here fills the building with toxic fumes. Move it outside first.") + gap
    end
    y = y + drawPlate(card, x, y, w, t) + gap

    -- condition
    local condC = d.cond > 50 and T.positive or T.warning
    local condTxt = tostring(d.cond) .. "%"
    if d.cond <= 50 then condTxt = condTxt .. " " .. DOT .. " may fail to start" end
    y = y + UI.meter(card, x, y, w, "CONDITION", condTxt, d.cond <= 50 and T.warning or nil, d.cond, condC) + gap

    if t.needs and #t.needs > 0 then
        y = y + UI.needs(card, x, y, w, t.needs) + gap
    end

    if d.on then
        y = y + UI.section(card, x, y, w, "POWERING", tostring(#d.items))
        for _, it in ipairs(d.items) do
            y = y + UI.row(card, x, y, w, nil, it.name, it.val)
        end
        y = y + UI.row(card, x, y, w, nil, d.name, d.baseStr and string.upper(d.baseStr) or nil)
        local tf = T.fontF3
        local th = T.px(24)
        local tc = T.text
        ZeD.Atoms.drawTextRight(card, (d.totalStr and string.upper(d.totalStr)) or string.format("%.4f L/H", d.total or 0),
            x + w - T.px(2), y + math.floor((th - ZeD.TM:getFontHeight(tf)) / 2), tf, tc)
        local lw = ZeD.TM:MeasureStringX(tf, "TOTAL")
        local vw = ZeD.TM:MeasureStringX(tf, (d.totalStr and string.upper(d.totalStr)) or "0.0000 L/H")
        card:drawText("TOTAL", x + w - T.px(2) - vw - T.px(12) - lw, y + math.floor((th - ZeD.TM:getFontHeight(tf)) / 2), tc.r, tc.g, tc.b, tc.a or 1, tf)
        y = y + th
    elseif #d.cans > 0 then
        y = y + UI.section(card, x, y, w, "ADD FUEL FROM YOUR BAGS", "ADDS")
        local room = math.max(0, d.max - d.fuel)
        for i, c in ipairs(d.cans) do
            local add = math.min(c.amt, room)
            local cc = c
            y = y + UI.pick(card, x, y, w, {
                tex = c.tex,
                name = string.format("%s (%.1f of %d L)", c.name, c.amt, math.floor(c.cap + 0.5)),
                where = c.where,
                gain = string.format("+%.1f L", add),
                button = "ADD",
                fid = "gen:can:" .. i,
                enabled = room > 0,
                run = function(card2, p)
                    ISWorldObjectContextMenu.doAddFuelGenerator(nil, t.obj, {}, cc.item, p:getPlayerNum())
                end,
            })
        end
    end
    return y - y0
end

OC.register(def)
